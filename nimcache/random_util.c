/* Generated by Nim Compiler v0.11.3 */
/*   (c) 2015 Andreas Rumpf */
/* The generated code is subject to the original license. */
/* Compiled for: Linux, amd64, gcc */
/* Command for C compiler:
   gcc -c  -w -Os  -I/data4/NimCompiler/Nim/lib -o /data4/NimStuff/NimFinLib/nimcache/random_util.o /data4/NimStuff/NimFinLib/nimcache/random_util.c */
#define NIM_INTBITS 64
#include "nimbase.h"
typedef struct TY199057 TY199057;
typedef struct TGenericSeq TGenericSeq;
typedef struct TNimType TNimType;
typedef struct TNimNode TNimNode;
struct  TGenericSeq  {
NI len;
NI reserved;
};
typedef N_NIMCALL_PTR(void, TY3289) (void* p, NI op);
typedef N_NIMCALL_PTR(void*, TY3294) (void* p);
struct  TNimType  {
NI size;
NU8 kind;
NU8 flags;
TNimType* base;
TNimNode* node;
void* finalizer;
TY3289 marker;
TY3294 deepcopy;
};
struct  TNimNode  {
NU8 kind;
NI offset;
TNimType* typ;
NCSTRING name;
NI len;
TNimNode** sons;
};
struct TY199057 {
  TGenericSeq Sup;
  NU32 data[SEQ_DECL_SIZE];
};
N_NIMCALL(TY199057*, newseq_199070)(NI len);
N_NIMCALL(void, TMP60)(void* p, NI op);
extern TNimType NTI124; /* uint32 */
TNimType NTI199057; /* seq[uint32] */
N_NIMCALL(void, TMP60)(void* p, NI op) {
	TY199057* a;
	NI LOC1;
	a = (TY199057*)p;
	LOC1 = 0;
	for (LOC1 = 0; LOC1 < a->Sup.len; LOC1++) {
	}
}

N_NIMCALL(TY199057*, bytestowords_199052)(NU8* bytes, NI bytesLen0) {
	TY199057* result;
	NI n;
	result = 0;
	n = (NI)((NI)((bytesLen0-1) / ((NI) 4)) + ((NI) 1));
	result = newseq_199070(((NI) (n)));
	{
		NI i_199108;
		NI HEX3Atmp_199164;
		NI res_199167;
		i_199108 = 0;
		HEX3Atmp_199164 = 0;
		HEX3Atmp_199164 = (n - 1);
		res_199167 = ((NI) 0);
		{
			while (1) {
				if (!(res_199167 <= HEX3Atmp_199164)) goto LA3;
				i_199108 = res_199167;
				{
					NI j_199127;
					NI res_199160;
					j_199127 = 0;
					res_199160 = ((NI) 0);
					{
						while (1) {
							NI index;
							NU32 data;
							NU8 LOC7;
							if (!(res_199160 <= ((NI) 3))) goto LA6;
							j_199127 = res_199160;
							index = (NI)((NI)(i_199108 * ((NI) 4)) + j_199127);
							LOC7 = 0;
							{
								if (!(index < bytesLen0)) goto LA10;
								LOC7 = bytes[index];
							}
							goto LA8;
							LA10: ;
							{
								LOC7 = ((NU8) 0);
							}
							LA8: ;
							data = ((NU32) (LOC7));
							result->data[i_199108] = (unsigned int)(result->data[i_199108] | (NU32)((NU32)(data) << (NU32)(((NU32) ((NI)(((NI) 8) * j_199127))))));
							res_199160 += ((NI) 1);
						} LA6: ;
					}
				}
				res_199167 += ((NI) 1);
			} LA3: ;
		}
	}
	return result;
}
NIM_EXTERNC N_NOINLINE(void, random_utilInit)(void) {
}

NIM_EXTERNC N_NOINLINE(void, random_utilDatInit)(void) {
NTI199057.size = sizeof(TY199057*);
NTI199057.kind = 24;
NTI199057.base = (&NTI124);
NTI199057.flags = 2;
NTI199057.marker = TMP60;
}
