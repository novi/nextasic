//
//  How to access GPIO registers from C-code on the Raspberry-Pi
//  Example program
//  15-January-2012
//  Dom and Gert
//  Revised: 15-Feb-2013


// Access from ARM Running Linux

#define BCM2708_PERI_BASE        0x3f000000
#define GPIO_BASE                (BCM2708_PERI_BASE + 0x200000) /* GPIO controller */


#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <vector>
#include <time.h>

#include "Realtime.h"

const int GPIO_OUT_CLK_BIT=23;	// pin 16
const int GPIO_IN_DATA_BIT=24;	// pin 18
const int GPIO_IN_RECV_BIT=22;	// pin 15
const int GPIO_OUT_SEND_BIT=27;	// pin 13
const int GPIO_OUT_DATA_BIT=17;	// pin 11

const int CLOCK_WAIT = 1;

#define PAGE_SIZE (4*1024)
#define BLOCK_SIZE (4*1024)

int  mem_fd;
void *gpio_map;

// I/O access
volatile unsigned *gpio;


// GPIO setup macros. Always use INP_GPIO(x) before using OUT_GPIO(x) or SET_GPIO_ALT(x,y)
#define SET_INP_GPIO(g) *(gpio+((g)/10)) &= ~(7<<(((g)%10)*3))
#define SET_OUT_GPIO(g) *(gpio+((g)/10)) |=  (1<<(((g)%10)*3))
#define SET_GPIO_ALT(g,a) *(gpio+(((g)/10))) |= (((a)<=3?(a)+4:(a)==4?3:2)<<(((g)%10)*3))

#define GPIO_SET *(gpio+7)  // sets   bits which are 1 ignores bits which are 0
#define GPIO_CLR *(gpio+10) // clears bits which are 1 ignores bits which are 0

#define GET_GPIO(g) (*(gpio+13)&(1<<g)) // 0 if LOW, (1<<g) if HIGH
#define SET_GPIO(g, d) ((d)?(GPIO_SET = 1<<(g)):(GPIO_CLR = 1<<(g)))

#define GPIO_PULL *(gpio+37) // Pull up/pull down
#define GPIO_PULLCLK0 *(gpio+38) // Pull up/pull down clock

void setup_io();

static volatile int dummy = 0;

void printBin(std::vector<uint8_t> data)
{
    for(uint8_t i=0; i<5;i++) {
        uint8_t d = data[i];
        for(uint8_t j=0; j<8; j++) {
            if (i > 0 && j % 4 == 0) printf(" ");
            printf((d >> j) & 1 ? "1": "0");
        }
    }
    printf("\n");
}

void sendData(std::vector<uint8_t> data)
{
    struct timespec tstart={0,0}, tend={0,0};
    // clock_gettime(CLOCK_MONOTONIC, &tstart);

	SET_GPIO(GPIO_OUT_SEND_BIT, 1);
    Realtime::delay(CLOCK_WAIT);
    SET_GPIO(GPIO_OUT_CLK_BIT, 1);
    Realtime::delay(CLOCK_WAIT);
    SET_GPIO(GPIO_OUT_SEND_BIT, 0);
    SET_GPIO(GPIO_OUT_CLK_BIT, 0);
    for(uint8_t i=0; i<5;i++) {
        uint8_t d = data[i];
        for(uint8_t j=0; j<8; j++) {
            SET_GPIO(GPIO_OUT_DATA_BIT, d & (1 << j) );
            // printf("%d", d & (1 << j) ? 1 : 0);
            Realtime::delay(CLOCK_WAIT);
            SET_GPIO(GPIO_OUT_CLK_BIT, 1);
            Realtime::delay(CLOCK_WAIT);
            SET_GPIO(GPIO_OUT_CLK_BIT, 0);
        }
    }
    SET_GPIO(GPIO_OUT_DATA_BIT, 0);
    for(uint8_t i=0; i<10;i++) {
        Realtime::delay(CLOCK_WAIT);
        SET_GPIO(GPIO_OUT_CLK_BIT, 1);
        Realtime::delay(CLOCK_WAIT);
        SET_GPIO(GPIO_OUT_CLK_BIT, 0);
    }
    //printf("sent\n");
    //clock_gettime(CLOCK_MONOTONIC, &tend);
    // printf("took about %.5f mseconds\n",
    //        ((double)tend.tv_sec + 1.0e-6*tend.tv_nsec) -
    //        ((double)tstart.tv_sec + 1.0e-6*tstart.tv_nsec));
}

int main(int argc, char **argv)
{
    int g,rep;

    Realtime::setup();
    // Set up gpi pointer for direct register access
    setup_io();


    SET_INP_GPIO(GPIO_OUT_CLK_BIT); // must use INP_GPIO before we can use OUT_GPIO
    SET_OUT_GPIO(GPIO_OUT_CLK_BIT);
    
	SET_INP_GPIO(GPIO_IN_DATA_BIT);
    SET_INP_GPIO(GPIO_IN_RECV_BIT);

	SET_INP_GPIO(GPIO_OUT_SEND_BIT);
	SET_OUT_GPIO(GPIO_OUT_SEND_BIT);
	SET_INP_GPIO(GPIO_OUT_DATA_BIT);
	SET_OUT_GPIO(GPIO_OUT_DATA_BIT);

/*
	bool connected=true;
	for(int i=0; i<5; ++i) {
		GPIO_CLR = 1 << GPIO_OUT_BIT;
		Realtime::delay(2);
		if(GET_GPIO(GPIO_IN_CLK_BIT) != 0) connected = false;
		Realtime::delay(2);
		GPIO_SET = 1 << GPIO_OUT_BIT;
		Realtime::delay(2);
		if(GET_GPIO(GPIO_IN_CLK_BIT) == 0) connected = false;
		Realtime::delay(2);
	}
	if(!connected)
		printf("**** GPIO %d and GPIO %d are not connected --"
					" no GPIO latency\n",GPIO_IN_CLK_BIT,GPIO_OUT_BIT);
	else
		printf("GPIO test ok\n");
*/
/*	for(;;) {
		printf("clk=%d\n", GET_GPIO(GPIO_IN_CLK_BIT));
		sleep(1);
	}
*/

    SET_GPIO(GPIO_OUT_CLK_BIT, 0);
    SET_GPIO(GPIO_OUT_DATA_BIT, 0);
    SET_GPIO(GPIO_OUT_SEND_BIT, 0);



    int action = 0;
    struct timespec tstart={0,0}, tend={0,0};
    for(;false;) { // skip
        printf("? ");
        scanf("%d", &action);
        switch(action) {
            case 1:
            sendData({0x63, 0x08, 0x00, 0x01, 0x5c}); // S key down
            break;
            case 2:
            sendData({0x63, 0x08, 0x00, 0x01, 0x5d}); // S key up
            break;
            case 3:
            clock_gettime(CLOCK_MONOTONIC, &tstart);
            for(;;) {
                clock_gettime(CLOCK_MONOTONIC, &tend);
                double time = ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) - 
                    ((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec);
                if (time > 19) {
                    break;
                }
                //sendData({0x63, 0x0a}); //reset packet A
                //usleep(1000*1);
                //sendData({0x63, 0x82}); //reset packet B
                //usleep(1000*1);
                //sendData({0x63, 0x8e}); //reset packet D
                //usleep(1000*1);
                sendData({0x63, 0x0e}); //reset packet F
                usleep(1000*1);
            }
            //usleep(1000*500); // 500ms
            // printf("sending snd ack...\n");
//             clock_gettime(CLOCK_MONOTONIC, &tstart);
//             for(;;) {
//                 clock_gettime(CLOCK_MONOTONIC, &tend);
//                 double time = ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) -
//                     ((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec);
//                 if (time > 10) {
//                     break;
//                 }
//                 sendData({0xe0});
//                 sendData({0xf0});
//             }
            break;
            
            case 4:
            sendData({0x63, 0x08, 0x00, 0x01, 0x5c}); // S key down
            usleep(1000*10);
            sendData({0x63, 0x08, 0x00, 0x01, 0x5d}); // S key up
            break;
            
            case 5:
            clock_gettime(CLOCK_MONOTONIC, &tstart);
            for(;;) {
                clock_gettime(CLOCK_MONOTONIC, &tend);
                double time = ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) -
                    ((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec);
                if (time > 5) {
                    break;
                }
                sendData({0xe0});
                sendData({0xf0});
            }
            break;
        }
        
    }
    

    std::vector<uint8_t> data = {0,0,0,0,0};

    for(;;) {
        //printf("\nwaiting data\n");
        for(;;) {
            SET_GPIO(GPIO_OUT_CLK_BIT, 0);
            Realtime::delay(CLOCK_WAIT);
            SET_GPIO(GPIO_OUT_CLK_BIT, 1);
            Realtime::delay(CLOCK_WAIT);
            if (GET_GPIO(GPIO_IN_RECV_BIT)) {
                break;
            }
        }
        //printf("recv data\n");
        Realtime::delay(CLOCK_WAIT);
        for(uint8_t i=0;i<5;i++) {
            uint8_t d = 0;
            for(uint8_t j=0;j<8;j++) {
                if (GET_GPIO(GPIO_IN_DATA_BIT))
                    d |= 1 << j;
                SET_GPIO(GPIO_OUT_CLK_BIT, 0);
                Realtime::delay(CLOCK_WAIT);
                SET_GPIO(GPIO_OUT_CLK_BIT, 1);
                Realtime::delay(CLOCK_WAIT);
            }
            data[i] = d;
        }
        //printBin(data);
        switch(data[0]) {
            case 0xf0:
            printf("44k\n");
            break;
            case 0xf8:
            printf("22k\n");
            break;
            case 0xe3:
            printf("S"); // got sound sample
            break;
            case 0x23:
            if (data[1] & 0x08) {
                printf("sound mute\n");
            }
            if (data[2] == 0 && data[3] == 0 && data[4] == 0) {
                printf("%02x ", data[1] & 0xf7);
            } else {
                printf("other sound setting 0x%02x 0x%02x 0x%02x 0x%02x\n", data[1], data[2], data[3], data[4]);
            }
            break;
            case 0xa3:
            printf("keyboard LED 0x%02x 0x%02x 0x%02x 0x%02x\n", data[1], data[2], data[3], data[4]);
            break;
            default:
            if (data[0] == 0x63 && data[1] == 0x80 && data[2] == 0xff && data[3] == 0xff && data[4] == 0x8f ) {
                printf("ping?\n");
            } else {
                printf("unknown command 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x\n", data[0], data[1], data[2], data[3], data[4]);
            }
            break;
        }
    }
    return 0;

} // main


//
// Set up a memory regions to access GPIO
//
void setup_io()
{
   /* open /dev/mem */
   if ((mem_fd = open("/dev/mem", O_RDWR|O_SYNC) ) < 0) {
      printf("can't open /dev/mem \n");
      exit(-1);
   }

   /* mmap GPIO */
   gpio_map = mmap(
      NULL,             //Any adddress in our space will do
      BLOCK_SIZE,       //Map length
      PROT_READ|PROT_WRITE,// Enable reading & writting to mapped memory
      MAP_SHARED,       //Shared with other processes
      mem_fd,           //File to map
      GPIO_BASE         //Offset to GPIO peripheral
   );

   close(mem_fd); //No need to keep mem_fd open after mmap

   if (gpio_map == MAP_FAILED) {
      printf("mmap error %d\n", (int)gpio_map);//errno also set!
      exit(-1);
   }

   // Always use volatile pointer!
   gpio = (volatile unsigned *)gpio_map;


} // setup_io
