/* Generated by Nim Compiler v0.11.3 */
/*   (c) 2015 Andreas Rumpf */
/* The generated code is subject to the original license. */
/* Compiled for: Linux, amd64, gcc */
/* Command for C compiler:
   gcc -c  -w -Os  -I/data4/NimCompiler/Nim/lib -o /data4/NimStuff/NimFinLib/nimcache/stdlib_algorithm.o /data4/NimStuff/NimFinLib/nimcache/stdlib_algorithm.c */
#define NIM_INTBITS 64
#include "nimbase.h"
typedef struct TY120008 TY120008;
typedef struct NimStringDesc NimStringDesc;
typedef struct TGenericSeq TGenericSeq;
typedef struct Cell44747 Cell44747;
typedef struct TNimType TNimType;
typedef struct Cellseq44763 Cellseq44763;
typedef struct Gcheap46616 Gcheap46616;
typedef struct Cellset44759 Cellset44759;
typedef struct Pagedesc44755 Pagedesc44755;
typedef struct Memregion26610 Memregion26610;
typedef struct Smallchunk25843 Smallchunk25843;
typedef struct Llchunk26604 Llchunk26604;
typedef struct Bigchunk25845 Bigchunk25845;
typedef struct Intset25817 Intset25817;
typedef struct Trunk25813 Trunk25813;
typedef struct Avlnode26608 Avlnode26608;
typedef struct Gcstat46614 Gcstat46614;
typedef struct TY259026 TY259026;
typedef struct TNimNode TNimNode;
typedef struct Basechunk25841 Basechunk25841;
typedef struct Freecell25833 Freecell25833;
struct  TGenericSeq  {
NI len;
NI reserved;
};
struct  NimStringDesc  {
  TGenericSeq Sup;
NIM_CHAR data[SEQ_DECL_SIZE];
};
struct  Cell44747  {
NI refcount;
TNimType* typ;
};
struct  Cellseq44763  {
NI len;
NI cap;
Cell44747** d;
};
struct  Cellset44759  {
NI counter;
NI max;
Pagedesc44755* head;
Pagedesc44755** data;
};
typedef Smallchunk25843* TY26622[512];
typedef Trunk25813* Trunkbuckets25815[256];
struct  Intset25817  {
Trunkbuckets25815 data;
};
struct  Memregion26610  {
NI minlargeobj;
NI maxlargeobj;
TY26622 freesmallchunks;
Llchunk26604* llmem;
NI currmem;
NI maxmem;
NI freemem;
NI lastsize;
Bigchunk25845* freechunkslist;
Intset25817 chunkstarts;
Avlnode26608* root;
Avlnode26608* deleted;
Avlnode26608* last;
Avlnode26608* freeavlnodes;
};
struct  Gcstat46614  {
NI stackscans;
NI cyclecollections;
NI maxthreshold;
NI maxstacksize;
NI maxstackcells;
NI cycletablesize;
NI64 maxpause;
};
struct  Gcheap46616  {
void* stackbottom;
NI cyclethreshold;
Cellseq44763 zct;
Cellseq44763 decstack;
Cellset44759 cycleroots;
Cellseq44763 tempstack;
NI recgclock;
Memregion26610 region;
Gcstat46614 stat;
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
typedef NI TY25820[8];
struct  Pagedesc44755  {
Pagedesc44755* next;
NI key;
TY25820 bits;
};
struct  Basechunk25841  {
NI prevsize;
NI size;
NIM_BOOL used;
};
struct  Smallchunk25843  {
  Basechunk25841 Sup;
Smallchunk25843* next;
Smallchunk25843* prev;
Freecell25833* freelist;
NI free;
NI acc;
NF data;
};
struct  Llchunk26604  {
NI size;
NI acc;
Llchunk26604* next;
};
struct  Bigchunk25845  {
  Basechunk25841 Sup;
Bigchunk25845* next;
Bigchunk25845* prev;
NI align;
NF data;
};
struct  Trunk25813  {
Trunk25813* next;
NI key;
TY25820 bits;
};
typedef Avlnode26608* TY26614[2];
struct  Avlnode26608  {
TY26614 link;
NI key;
NI upperbound;
NI level;
};
struct  TNimNode  {
NU8 kind;
NI offset;
TNimType* typ;
NCSTRING name;
NI len;
TNimNode** sons;
};
struct  Freecell25833  {
Freecell25833* next;
NI zerofield;
};
struct TY120008 {
  TGenericSeq Sup;
  NimStringDesc* data[SEQ_DECL_SIZE];
};
struct TY259026 {
  TGenericSeq Sup;
  NF data[SEQ_DECL_SIZE];
};
N_NIMCALL(TY120008*, reversed_331653)(NimStringDesc** a, NI aLen0, NI first, NI last);
N_NIMCALL(TY120008*, newseq_291437)(NI len);
N_NIMCALL(NimStringDesc*, copyStringRC1)(NimStringDesc* src);
static N_INLINE(void, nimGCunrefNoCycle)(void* p);
static N_INLINE(Cell44747*, usrtocell_48246)(void* usr);
static N_INLINE(void, rtladdzct_49804)(Cell44747* c);
N_NOINLINE(void, addzct_48217)(Cellseq44763* s, Cell44747* c);
N_NIMCALL(TY259026*, reversed_331919)(NF* a, NI aLen0, NI first, NI last);
N_NIMCALL(TY259026*, newseq_291480)(NI len);
extern Gcheap46616 gch_46648;

static N_INLINE(Cell44747*, usrtocell_48246)(void* usr) {
	Cell44747* result;
	result = 0;
	result = ((Cell44747*) ((NI)((NU64)(((NI) (usr))) - (NU64)(((NI)sizeof(Cell44747))))));
	return result;
}

static N_INLINE(void, rtladdzct_49804)(Cell44747* c) {
	addzct_48217((&gch_46648.zct), c);
}

static N_INLINE(void, nimGCunrefNoCycle)(void* p) {
	Cell44747* c;
	c = usrtocell_48246(p);
	{
		(*c).refcount -= ((NI) 8);
		if (!((NU64)((*c).refcount) < (NU64)(((NI) 8)))) goto LA3;
		rtladdzct_49804(c);
	}
	LA3: ;
}

N_NIMCALL(TY120008*, reversed_331653)(NimStringDesc** a, NI aLen0, NI first, NI last) {
	TY120008* result;
	NI x;
	NI y;
	result = 0;
	result = newseq_291437(((NI) ((NI)((NI)(((NI) (last)) - ((NI) (first))) + ((NI) 1)))));
	x = ((NI) (first));
	y = ((NI) (last));
	{
		while (1) {
			NimStringDesc* LOC3;
			if (!(x <= ((NI) (last)))) goto LA2;
			LOC3 = 0;
			LOC3 = result->data[x]; result->data[x] = copyStringRC1(a[y]);
			if (LOC3) nimGCunrefNoCycle(LOC3);
			y -= ((NI) 1);
			x += ((NI) 1);
		} LA2: ;
	}
	return result;
}

N_NIMCALL(TY120008*, reversed_331637)(NimStringDesc** a, NI aLen0) {
	TY120008* result;
	result = 0;
	result = reversed_331653(a, aLen0, ((NI) 0), ((NI) ((aLen0-1))));
	return result;
}

N_NIMCALL(TY259026*, reversed_331919)(NF* a, NI aLen0, NI first, NI last) {
	TY259026* result;
	NI x;
	NI y;
	result = 0;
	result = newseq_291480(((NI) ((NI)((NI)(((NI) (last)) - ((NI) (first))) + ((NI) 1)))));
	x = ((NI) (first));
	y = ((NI) (last));
	{
		while (1) {
			if (!(x <= ((NI) (last)))) goto LA2;
			result->data[x] = a[y];
			y -= ((NI) 1);
			x += ((NI) 1);
		} LA2: ;
	}
	return result;
}

N_NIMCALL(TY259026*, reversed_331903)(NF* a, NI aLen0) {
	TY259026* result;
	result = 0;
	result = reversed_331919(a, aLen0, ((NI) 0), ((NI) ((aLen0-1))));
	return result;
}
NIM_EXTERNC N_NOINLINE(void, stdlib_algorithmInit)(void) {
}

NIM_EXTERNC N_NOINLINE(void, stdlib_algorithmDatInit)(void) {
}
