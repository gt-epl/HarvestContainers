#ifndef INTERRUPTS_H
#define INTERRUPTS_H

//Sample interval, in nanoseconds
//#define IRQ_SAMPLE_RATE 1*1000*1000*1000
//#define IRQ_SAMPLE_RATE 1*1000*1000
static unsigned long long IRQ_SAMPLE_RATE = 1*1000*1000*1000ULL;

int interruptSampleCount, interruptRebalanceCount;

struct timespec irq_sample_time;

struct harvest_core {
  int cpuid;
  unsigned long long curr_weight;
};

unsigned long long harvest_core_weights[64];
//unsigned long long curr_irq_times[64];
unsigned long long prev_irq_times[64];

int fd_qidlecpu;

int getInterruptWeights();

/* Begin Debug */
struct hc {
  int cpuid;
  unsigned long long curr_weight;
};

struct irq_log_msg {
  struct hc harvest_cores[64];
  unsigned long long harvest_core_weights[64];
};
int irq_log_count;
int printIRQDebug();

void printSingle(int cpuid, unsigned long long values[64]);

struct irq_logentry {
    /* Start of event in sec and nanosec */
    unsigned long startSec;
    unsigned long startNSec;
    /* End of event in sec and nanosec */
    unsigned long endSec;
    unsigned long endNSec;
    /* IdleCPU mask at time of event */
    unsigned long long harvest_cores;
};

void addIRQLog(struct timespec *eventStart, struct timespec *eventEnd);

struct irq_logentry *irq_events;

/* End Debug */

#endif