#ifndef QUEUE_H_
#define QUEUE_H_

#include "segel.h"

typedef struct queue* Queue;
typedef struct qnode* Qnode;


Queue createQueue();
void enqueue(Queue q,int connfd,struct timeval req_time);
void dequeue(Queue q);
int getSize(Queue q);
int removeRand(Queue q);
int getData(Qnode q);
struct timeval getArrivalTime(Qnode q);
Qnode popHead(Queue q);

#endif /*QUEUE_H*/