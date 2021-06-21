
#include <stdio.h>
#include <stdlib.h>
#include "queue.h"
#include "segel.h"

struct qnode
{
    int data;
    struct timeval req_arrival;
    Qnode next;
    Qnode prev;
};

struct queue{
    int size;
    Qnode dummy_head;
    Qnode dummy_tail;
};



Queue createQueue(int size)
{
    Queue q = malloc(sizeof(*q));
    q->size = 0;
    Qnode head = (Qnode)malloc(sizeof(*head));
    Qnode tail = (Qnode)malloc(sizeof(*tail));
    head->data=-1;
    head->data=-2;
    q->dummy_head = head;
    q->dummy_tail = tail;
    q->dummy_head->next = q->dummy_tail;
    q->dummy_tail->prev=q->dummy_head;
    q->dummy_tail->next = NULL;
    q->dummy_head->prev = NULL;
    return q;
}

void enqueue(Queue q,int connfd,struct timeval req_time)
{
    Qnode new_node = (Qnode)malloc(sizeof(*new_node));
    new_node->data = connfd;
    new_node->req_arrival = req_time;
    new_node->next = q->dummy_head->next;
    new_node->prev = q->dummy_head;
    q->dummy_head->next->prev=new_node;
    q->dummy_head->next=new_node;
    q->size++;
}

void dequeue(Queue q)
{
    if (q->size == 0)
    {
        return ;
    }
    Qnode tail = q->dummy_tail->prev;
    q->dummy_tail->prev = tail->prev;
    tail->prev->next = q->dummy_tail;
    free(tail);
    q->size--;
    return ;
}

Qnode popHead(Queue q)
{
        if (q->size == 0)
    {
        return NULL;
    }
    Qnode tail = q->dummy_tail->prev;
    return tail;
}

int getSize(Queue q)
{
    return q->size;
}

int removeRand(Queue q)
{
    srand(time(NULL));
    int index = 0;
    if (q->size > 1 )
    {
        index = rand() % (q->size-1);
    }
    Qnode curr=q->dummy_head;  
    for (int i = 0; i < index; i++)
    {
        curr= curr->next;
    }
    Qnode del_node = curr->next;
    int res = del_node->data;
    curr->next = curr->next->next;
    del_node->next->prev=curr;
    free(del_node);
    q->size--;
    return res;
}

struct timeval getArrivalTime(Qnode q)
{
    return q->req_arrival;
}

int getData(Qnode q)
{
    return q->data;
}