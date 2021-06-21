#ifndef __REQUEST_H__

void requestHandle(int fd,struct timeval req_arrive_time,struct timeval req_dispatch_time,Qwadra thread_info);

#endif
