////  noise_reducer.h
//  CleanAudio
//
//  Created by Mostafizur Rahman on 17/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

#ifndef noise_reducer_h
#define noise_reducer_h


#include <stdio.h>
#include "denoise.h"

void processAudio(const char * input_path, const char * out_path);
struct SomeCLibCallbacks {
    void (* _Nonnull printGreeting)(unsigned long long * modifier);
};
typedef struct SomeCLibCallbacks SomeCLibCallbacks;

extern void SomeCLibSetup(const SomeCLibCallbacks * callbacks);
void cancelCleaning(void);
extern void SomeCLibTest(void);
void resetCounter(void);


void nr_end_cleaning(void);
void nr_clean_audio(const short *source_array);
void nr_start_clean(const char * out_path);

#endif /* noise_reducer_h */
