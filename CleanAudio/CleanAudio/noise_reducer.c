//
//  noise_reducer.c
//  CleanAudio
//
//  Created by Mostafizur Rahman on 17/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

#include "noise_reducer.h"
#ifdef DEBUG
#include <assert.h>
#endif

static SomeCLibCallbacks sCallbacks;

extern void SomeCLibSetup(const SomeCLibCallbacks * callbacks) {
    sCallbacks = *callbacks;
}


unsigned long long counter = 0;
int performCleaning = 0;
void resetCounter(void){
    counter = 0;
}

void cancelCleaning(void){
    performCleaning = 0;
    resetCounter();
}


void processAudio(const char * input_path, const char * out_path){
    int i;
    int first = 0;
    float x[FRAME_SIZE];
    FILE *f1, *fout;
    DenoiseState *st;
    st = rnnoise_create();
    f1 = fopen(input_path, "r");
    fout = fopen(out_path, "w");
    short tmp[FRAME_SIZE] = {};
    performCleaning = 1;
    while (performCleaning == 1) {
        
        unsigned long count = fread(tmp, sizeof(short), FRAME_SIZE, f1);
        if (first < 2){
            first++;
            continue;
        }
        for (i=0;i<FRAME_SIZE;i++) x[i] = tmp[i];
        rnnoise_process_frame(st, x, x);
        for (i=0;i<FRAME_SIZE;i++) tmp[i] = x[i];
        if (count < 480){
            printf("lok");
        }
        fwrite(tmp, sizeof(short), count, fout);
        if (feof(f1)) break;
//        counter = counter + FRAME_SIZE;
//        sCallbacks.printGreeting(&counter);
    }
    rnnoise_destroy(st);
    fclose(f1);
    fclose(fout);
}

DenoiseState *denoise_state;
FILE *outputFile;

void nr_start_clean( const char * out_path) {
    
    denoise_state = rnnoise_create();
    outputFile = fopen(out_path, "w");
}

void nr_clean_audio(const short *source_array){
//    float x[FRAME_SIZE] = {0};
//    for (int j = 0; j<FRAME_SIZE; j++){
//        x[j] = source_array[j];
//    }
//    rnnoise_process_frame(denoise_state, x, x);
    short output[FRAME_SIZE] = {0};
    for (int k = 0; k < FRAME_SIZE; k++){
        output[k] = source_array[k];
    }
    fwrite(output, sizeof(short), FRAME_SIZE, outputFile);
}

void nr_end_cleaning(void){
    if (denoise_state != NULL){
        denoise_state = NULL;
    }
    fclose(outputFile);
    outputFile = NULL;
}
