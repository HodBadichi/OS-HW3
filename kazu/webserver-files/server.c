#include "segel.h"
#include "request.h"
#include "queue.h"

// 
// server.c: A very, very simple web server
//
// To run:
//  ./server <portnum (above 2000)>
//
// Repeatedly handles HTTP requests sent to this port number.
// Most of the work is done within routines written in request.c
//

// HW3: Parse the new arguments too
Queue tasks_queue; 
int tasks_cnt = 0;
int max_tasks;
int mtf_cnt;
pthread_cond_t queue_cond;
pthread_cond_t master_cond;
pthread_mutex_t queue_mutex;

void getargs(int *port, int *num_of_threads, int *num_of_req,  int argc, char *argv[]) 
{
    if (argc < 4) {
	fprintf(stderr, "Usage: %s <port>\n", argv[0]);
	exit(1);
    }
    *port = atoi(argv[1]);
    *num_of_threads = atoi(argv[2]);
    *num_of_req = atoi(argv[3]) ;
}

void block()
{
    while(max_tasks == tasks_cnt){
        pthread_cond_wait(&master_cond, &queue_mutex);
    }

}

void dropHead()
{
    Close(getData(popHead(tasks_queue)));
    dequeue(tasks_queue);
    tasks_cnt--;
}

void randomDrop()
{
    int cnt = (getSize(tasks_queue)/4) +((getSize(tasks_queue) % 4)!=0);
    for (int i=0; i<cnt; i++){
        Close(removeRand(tasks_queue));
        tasks_cnt--;
    }
}

void* startThread(void* p_pair)
{
    char* overload = ((Pair)p_pair)->argv;
    Qwadra thread_info = (Qwadra)malloc(sizeof(*thread_info));
    thread_info->thread_id = ((Pair)p_pair)->thread_id;
    thread_info->Stat_thread_dynamic = 0;
    thread_info->Stat_thread_static = 0;
    thread_info->Stat_thread_total = 0;
    while(1){
        pthread_mutex_lock(&queue_mutex);
        while (getSize(tasks_queue) == 0){
            pthread_cond_wait(&queue_cond, &queue_mutex);
        }
        Qnode curr_node = popHead(tasks_queue);
        struct timeval worker_pick_time;
        struct timeval dispatch_time ;
        struct timeval arr_req_time = getArrivalTime(curr_node);
        gettimeofday(&worker_pick_time,NULL);
        int connfd = getData(curr_node);
        dequeue(tasks_queue);
        timersub(&worker_pick_time,&arr_req_time,&dispatch_time);
    
        pthread_mutex_unlock(&queue_mutex);
        requestHandle(connfd,arr_req_time,dispatch_time,thread_info);
        Close(connfd);
        pthread_mutex_lock(&queue_mutex);
        tasks_cnt--;
        if (tasks_cnt < max_tasks && !strcmp(overload, "block")){
            pthread_cond_signal(&master_cond);
        }
        pthread_mutex_unlock(&queue_mutex);

    }
    free(p_pair);
} 
 
void submitTask(int connfd, char* clean_type,struct timeval req_arrival) 
{
    pthread_mutex_lock(&queue_mutex);
    if (tasks_cnt == max_tasks)
    {
        if(!strcmp(clean_type,"block")){            
            block();
        }
        else if(!strcmp(clean_type,"dt")){
            Close (connfd);
            pthread_mutex_unlock(&queue_mutex);
            return;

        }
        else if (!strcmp(clean_type, "dh")){
            if (getSize(tasks_queue) == 0)
            {
                Close(connfd);
                pthread_mutex_unlock(&queue_mutex);
                return;
            }
            dropHead();
        }
        else if(!strcmp(clean_type,"random")){
            if (getSize(tasks_queue) == 0)
            {
                Close(connfd);
                pthread_mutex_unlock(&queue_mutex);
                return;
            }
            randomDrop();
        }
        else{
            fprintf(stderr, "illegal usage");
            exit(1);
        }
    }
    enqueue(tasks_queue, connfd,req_arrival);
    tasks_cnt++;
    pthread_cond_signal(&queue_cond);
    pthread_mutex_unlock(&queue_mutex);
    
}

int main(int argc, char *argv[])
{
    srand(time(NULL));
    int listenfd, connfd, port, num_of_threads, num_of_req, clientlen;
    getargs(&port,&num_of_threads,&num_of_req,  argc, argv);
    max_tasks = num_of_req;
    tasks_queue=createQueue();
    pthread_mutex_init(&queue_mutex, NULL);
    pthread_cond_init(&queue_cond, NULL);
    pthread_t theards[num_of_threads];
    for (int i=0; i<num_of_threads; i++)
    {
        Pair my_pair = malloc(sizeof(*my_pair));
        my_pair->argv=argv[4];
        my_pair->thread_id = i;
         pthread_create(&theards[i], NULL,&startThread, (void*)my_pair); 
    }
        listenfd = Open_listenfd(port);
        struct sockaddr_in clientaddr;
        struct timeval temp_time;
        clientlen = sizeof(clientaddr);
    while (1) {
        connfd = Accept(listenfd, (SA *)&clientaddr, (socklen_t *) &clientlen);
        gettimeofday(&temp_time,NULL);
        submitTask(connfd, argv[4],temp_time);
    }

}
    


 
