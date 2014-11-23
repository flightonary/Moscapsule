/*
Copyright (c) 2009-2013 Roger Light <roger@atchoo.org>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of mosquitto nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
*/

#include <assert.h>
#include <string.h>

#ifdef WIN32
#include <winsock2.h>
#endif


#include "mosquitto.h"
#include "memory_mosq.h"
#include "net_mosq.h"
#include "send_mosq.h"
#include "time_mosq.h"
#include "tls_mosq.h"
#include "util_mosq.h"

#ifdef WITH_BROKER
#include "mosquitto_broker.h"
#endif

int _mosquitto_packet_alloc(struct _mosquitto_packet *packet)
{
	uint8_t remaining_bytes[5], byte;
	uint32_t remaining_length;
	int i;

	assert(packet);

	remaining_length = packet->remaining_length;
	packet->payload = NULL;
	packet->remaining_count = 0;
	do{
		byte = remaining_length % 128;
		remaining_length = remaining_length / 128;
		/* If there are more digits to encode, set the top bit of this digit */
		if(remaining_length > 0){
			byte = byte | 0x80;
		}
		remaining_bytes[packet->remaining_count] = byte;
		packet->remaining_count++;
	}while(remaining_length > 0 && packet->remaining_count < 5);
	if(packet->remaining_count == 5) return MOSQ_ERR_PAYLOAD_SIZE;
	packet->packet_length = packet->remaining_length + 1 + packet->remaining_count;
	packet->payload = _mosquitto_malloc(sizeof(uint8_t)*packet->packet_length);
	if(!packet->payload) return MOSQ_ERR_NOMEM;

	packet->payload[0] = packet->command;
	for(i=0; i<packet->remaining_count; i++){
		packet->payload[i+1] = remaining_bytes[i];
	}
	packet->pos = 1 + packet->remaining_count;

	return MOSQ_ERR_SUCCESS;
}

void _mosquitto_check_keepalive(struct mosquitto *mosq)
{
	time_t last_msg_out;
	time_t last_msg_in;
	time_t now = mosquitto_time();
#ifndef WITH_BROKER
	int rc;
#endif

	assert(mosq);
#if defined(WITH_BROKER) && defined(WITH_BRIDGE)
	/* Check if a lazy bridge should be timed out due to idle. */
	if(mosq->bridge && mosq->bridge->start_type == bst_lazy
				&& mosq->sock != INVALID_SOCKET
				&& now - mosq->last_msg_out >= mosq->bridge->idle_timeout){

		_mosquitto_log_printf(NULL, MOSQ_LOG_NOTICE, "Bridge connection %s has exceeded idle timeout, disconnecting.", mosq->id);
		_mosquitto_socket_close(mosq);
		return;
	}
#endif
	pthread_mutex_lock(&mosq->msgtime_mutex);
	last_msg_out = mosq->last_msg_out;
	last_msg_in = mosq->last_msg_in;
	pthread_mutex_unlock(&mosq->msgtime_mutex);
	if(mosq->keepalive && mosq->sock != INVALID_SOCKET &&
			(now - last_msg_out >= mosq->keepalive || now - last_msg_in >= mosq->keepalive)){

		if(mosq->state == mosq_cs_connected && mosq->ping_t == 0){
			_mosquitto_send_pingreq(mosq);
			/* Reset last msg times to give the server time to send a pingresp */
			pthread_mutex_lock(&mosq->msgtime_mutex);
			mosq->last_msg_in = now;
			mosq->last_msg_out = now;
			pthread_mutex_unlock(&mosq->msgtime_mutex);
		}else{
#ifdef WITH_BROKER
			if(mosq->listener){
				mosq->listener->client_count--;
				assert(mosq->listener->client_count >= 0);
			}
			mosq->listener = NULL;
#endif
			_mosquitto_socket_close(mosq);
#ifndef WITH_BROKER
			pthread_mutex_lock(&mosq->state_mutex);
			if(mosq->state == mosq_cs_disconnecting){
				rc = MOSQ_ERR_SUCCESS;
			}else{
				rc = 1;
			}
			pthread_mutex_unlock(&mosq->state_mutex);
			pthread_mutex_lock(&mosq->callback_mutex);
			if(mosq->on_disconnect){
				mosq->in_callback = true;
				mosq->on_disconnect(mosq, mosq->userdata, rc);
				mosq->in_callback = false;
			}
			pthread_mutex_unlock(&mosq->callback_mutex);
#endif
		}
	}
}

uint16_t _mosquitto_mid_generate(struct mosquitto *mosq)
{
	assert(mosq);

	mosq->last_mid++;
	if(mosq->last_mid == 0) mosq->last_mid++;
	
	return mosq->last_mid;
}

/* Search for + or # in a topic. Return MOSQ_ERR_INVAL if found.
 * Also returns MOSQ_ERR_INVAL if the topic string is too long.
 * Returns MOSQ_ERR_SUCCESS if everything is fine.
 */
int _mosquitto_topic_wildcard_len_check(const char *str)
{
	int len = 0;
	while(str && str[0]){
		if(str[0] == '+' || str[0] == '#'){
			return MOSQ_ERR_INVAL;
		}
		len++;
		str = &str[1];
	}
	if(len > 65535) return MOSQ_ERR_INVAL;

	return MOSQ_ERR_SUCCESS;
}

/* Search for + or # in a topic, check they aren't in invalid positions such as foo/#/bar, foo/+bar or foo/bar#.
 * Return MOSQ_ERR_INVAL if invalid position found.
 * Also returns MOSQ_ERR_INVAL if the topic string is too long.
 * Returns MOSQ_ERR_SUCCESS if everything is fine.
 */
int _mosquitto_topic_wildcard_pos_check(const char *str)
{
	char c = '\0';
	int len = 0;
	while(str && str[0]){
		if(str[0] == '+'){
			if((c != '\0' && c != '/') || (str[1] != '\0' && str[1] != '/')){
				return MOSQ_ERR_INVAL;
			}
		}else if(str[0] == '#'){
			if((c != '\0' && c != '/')  || str[1] != '\0'){
				return MOSQ_ERR_INVAL;
			}
		}
		len++;
		c = str[0];
		str = &str[1];
	}
	if(len > 65535) return MOSQ_ERR_INVAL;

	return MOSQ_ERR_SUCCESS;
}

/* Does a topic match a subscription? */
int mosquitto_topic_matches_sub(const char *sub, const char *topic, bool *result)
{
	int slen, tlen;
	int spos, tpos;
	bool multilevel_wildcard = false;

	if(!sub || !topic || !result) return MOSQ_ERR_INVAL;

	slen = strlen(sub);
	tlen = strlen(topic);

	if(slen && tlen){
		if((sub[0] == '$' && topic[0] != '$')
				|| (topic[0] == '$' && sub[0] != '$')){

			*result = false;
			return MOSQ_ERR_SUCCESS;
		}
	}

	spos = 0;
	tpos = 0;

	while(spos < slen && tpos < tlen){
		if(sub[spos] == topic[tpos]){
			if(tpos == tlen-1){
				/* Check for e.g. foo matching foo/# */
				if(spos == slen-3 
						&& sub[spos+1] == '/'
						&& sub[spos+2] == '#'){
					*result = true;
					multilevel_wildcard = true;
					return MOSQ_ERR_SUCCESS;
				}
			}
			spos++;
			tpos++;
			if(spos == slen && tpos == tlen){
				*result = true;
				return MOSQ_ERR_SUCCESS;
			}else if(tpos == tlen && spos == slen-1 && sub[spos] == '+'){
				spos++;
				*result = true;
				return MOSQ_ERR_SUCCESS;
			}
		}else{
			if(sub[spos] == '+'){
				spos++;
				while(tpos < tlen && topic[tpos] != '/'){
					tpos++;
				}
				if(tpos == tlen && spos == slen){
					*result = true;
					return MOSQ_ERR_SUCCESS;
				}
			}else if(sub[spos] == '#'){
				multilevel_wildcard = true;
				if(spos+1 != slen){
					*result = false;
					return MOSQ_ERR_SUCCESS;
				}else{
					*result = true;
					return MOSQ_ERR_SUCCESS;
				}
			}else{
				*result = false;
				return MOSQ_ERR_SUCCESS;
			}
		}
	}
	if(multilevel_wildcard == false && (tpos < tlen || spos < slen)){
		*result = false;
	}

	return MOSQ_ERR_SUCCESS;
}

#ifdef REAL_WITH_TLS_PSK
int _mosquitto_hex2bin(const char *hex, unsigned char *bin, int bin_max_len)
{
	BIGNUM *bn = NULL;
	int len;

	if(BN_hex2bn(&bn, hex) == 0){
		if(bn) BN_free(bn);
		return 0;
	}
	if(BN_num_bytes(bn) > bin_max_len){
		BN_free(bn);
		return 0;
	}

	len = BN_bn2bin(bn, bin);
	BN_free(bn);
	return len;
}
#endif

FILE *_mosquitto_fopen(const char *path, const char *mode)
{
#ifdef WIN32
	char buf[MAX_PATH];
	int rc;
	rc = ExpandEnvironmentStrings(path, buf, MAX_PATH);
	if(rc == 0 || rc == MAX_PATH){
		return NULL;
	}else{
		return fopen(buf, mode);
	}
#else
	return fopen(path, mode);
#endif
}

