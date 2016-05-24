module derelict.portmidi.portmidi;

private {
    import derelict.util.loader;
    import derelict.util.system;

    static if(Derelict_OS_Windows)
        enum libNames = "libPortMidi.dll";

    else static if(Derelict_OS_Mac)
        enum libNames = "libportmidi.dylib, /usr/local/lib/libportmidi.dylib";

    else static if(Derelict_OS_Posix)
        enum libNames = "libportmidi.so, /usr/local/lib/libportmidi.so";
        
    else
        static assert(0, "Need to implement libportmidi libNames for this operating system.");
}

enum int PM_DEFAULT_SYSEX_BUFFER_SIZE = 1024;

enum int HDRLENGTH = 50;
enum uint PM_HOST_ERROR_MSG_LEN = 256;
enum int pmNoDevice = -1;

enum {
    PM_FILT_ACTIVE = (1 << 0x0E),
    PM_FILT_SYSEX = (1 << 0x00),
    PM_FILT_CLOCK = (1 << 0x08),
    PM_FILT_PLAY = ((1 << 0x0A) | (1 << 0x0C) | (1 << 0x0B)),
    PM_FILT_TICK = (1 << 0x09),
    PM_FILT_FD = (1 << 0x0D),
    PM_FILT_UNDEFINED = PM_FILT_FD,
    PM_FILT_RESET = (1 << 0X0F),
    PM_FILT_REALTIME = PM_FILT_ACTIVE | PM_FILT_SYSEX | PM_FILT_CLOCK |
                        PM_FILT_PLAY | PM_FILT_UNDEFINED | PM_FILT_RESET | PM_FILT_TICK,

    PM_FILT_NOTE = ((1 << 0x19) | (1 << 0x18)),
    PM_FILT_CHANNEL_AFTERTOUCH = (1 << 0x1D),
    PM_FILT_POLY_AFTERTOUCH = (1 << 0x1A),
    PM_FILT_AFTERTOUCH = PM_FILT_CHANNEL_AFTERTOUCH | PM_FILT_POLY_AFTERTOUCH,
    PM_FILT_PROGRAM = (1 << 0x1C),
    PM_FILT_CONTROL = (1 << 0x1B),
    PM_FILT_PITCHBEND = (1 << 0x1E),
    PM_FILT_MTC = (1 << 0x01),
    PM_FILT_SONG_POSITION = (1 << 0x02),
    PM_FILT_SONG_SELECT = (1 << 0x03),
    PM_FILT_TUNE = (1 << 0x06),
    PM_FILT_SYSTEMCOMMON = (PM_FILT_MTC | PM_FILT_SONG_POSITION | PM_FILT_SONG_SELECT | PM_FILT_TUNE)   
}

alias PmError = int;

enum : PmError {
    pmNoError = 0,
    pmHostError = -10000,
    pmInvalidDeviceId,
    pmInsufficientMemory,
    pmBufferTooSmall,
    pmBufferOverflow,
    pmBadPtr,
    pmBadData,
    pmInternalError,
    pmBufferMaxSize
}

alias PortMidiStream = void;
alias PmStream = PortMidiStream;
alias PmDeviceID = int;
alias PmTimestamp = long;
alias PmMessage = long;

//From pmutil.h
alias PmQueue = void;

extern(C) nothrow alias PmTimeProcPtr = PmTimestamp* function(void* time_info);

struct PmDeviceInfo {
    int structVersion;
    const char* interf;
    const char* name;
    int input;
    int output;
    int opened;
}

struct PmEvent
{
    PmMessage message;
    PmTimestamp timestamp;
}

//Replicates behavior of the following line in portmidi.h:
//#define PmBefore(t1,t2) ((t1-t2) < 0)
bool PmBefore(T)(T t1, T t2) {
    return t1 - t2 < 0;
}

//Replicates the behavior of the following line in portmidi.h:
//#define Pm_Channel(channel) (1<<(channel))
int Pm_Channel(int channel) {
    return 1 << channel;
}

//Replicates the Pm_Message* macros in portmidi.h
PmMessage Pm_Message(long status, long data1, long data2) {
    return ((data2 << 16) & 0xff0000) | ((data1 << 8) & 0xff00) | (status & 0xff);
}

long Pm_MessageStatus(PmMessage msg) {
    return msg & 0xff;
}

long Pm_MessageData1(PmMessage msg) {
    return (msg >> 8) & 0xff;
}

long Pm_MessageData2(PmMessage msg) {
    return (msg >> 16) & 0xff;
}

extern(C) @nogc nothrow {
    alias da_Pm_Initialize = PmError function();
    alias da_Pm_Terminate = PmError function();
    alias da_Pm_HasHostError = int function(PortMidiStream* stream);
    alias da_Pm_GetErrorText = const(char)* function(PmError errnum);
    alias da_Pm_GetHostErrorText = const(char)* function(char* msg, uint len);
    alias da_Pm_CountDevices = int function();
    alias da_Pm_GetDefaultInputDeviceID = PmDeviceID function();
    alias da_Pm_GetDefaultOutputDeviceID = PmDeviceID function();
    alias da_Pm_GetDeviceInfo = const(PmDeviceInfo)* function(PmDeviceID id);

    alias da_Pm_OpenInput = PmError function(   PortMidiStream** stream,
                                                PmDeviceID inputDevice,
                                                void* inputDriverInfo,
                                                long bufferSize,
                                                PmTimeProcPtr time_proc,
                                                void* time_info);

    alias da_Pm_OpenOutput = PmError function(   PortMidiStream** stream,
                                                PmDeviceID outputDevice,
                                                void* outputDriverInfo,
                                                long bufferSize,
                                                PmTimeProcPtr time_proc,
                                                void* time_info,
                                                long latency);

    alias da_Pm_SetFilter = PmError function(PortMidiStream* stream, long filters);
    alias da_Pm_SetChannelMask = PmError function(PortMidiStream* stream, int mask);
    alias da_Pm_Abort = PmError function(PortMidiStream* stream);
    alias da_Pm_Close = PmError function(PortMidiStream* stream);
    alias da_Pm_Read = int function(PortMidiStream* stream, PmEvent* buffer, long length);
    alias da_Pm_Poll = PmError function(PortMidiStream* stream);
    alias da_Pm_Write = PmError function(PortMidiStream* stream, PmEvent* buffer, long length);
    alias da_Pm_WriteShort = PmError function(PortMidiStream* stream, PmTimestamp when, long msg);
    alias da_Pm_WriteSysEx = PmError function(PortMidiStream* stream, PmTimestamp when, ubyte* msg);

    //From pmutil.h
    alias da_Pm_QueueCreate = PmQueue* function(long num_msgs, int bytes_per_msg);
    alias da_Pm_QueueDestroy = PmError function(PmQueue* queue);
    alias da_Pm_Dequeue = PmError function(PmQueue* queue, void* msg);
    alias da_Pm_Enqueue = PmError function(PmQueue* queue, void* msg);
    alias da_Pm_QueueFull = int function(PmQueue* queue);
    alias da_Pm_QueueEmpty = int function(PmQueue* queue);
    alias da_Pm_QueuePeek = void* function(PmQueue* queue);
    alias da_Pm_SetOverflow = PmError function(PmQueue* queue);
}

__gshared {
    da_Pm_Initialize Pm_Initialize;
    da_Pm_Terminate Pm_Terminate;
    da_Pm_HasHostError Pm_HasHostError;
    da_Pm_GetErrorText Pm_GetErrorText;
    da_Pm_GetHostErrorText Pm_GetHostErrorText;
    da_Pm_CountDevices Pm_CountDevices;
    da_Pm_GetDefaultInputDeviceID Pm_GetDefaultInputDeviceID;
    da_Pm_GetDefaultOutputDeviceID Pm_GetDefaultOutputDeviceID;
    da_Pm_GetDeviceInfo Pm_GetDeviceInfo;
    da_Pm_OpenInput Pm_OpenInput;
    da_Pm_OpenOutput Pm_OpenOutput;
    da_Pm_SetFilter Pm_SetFilter;
    da_Pm_SetChannelMask Pm_SetChannelMask;
    da_Pm_Abort Pm_Abort;
    da_Pm_Close Pm_Close;
    da_Pm_Read Pm_Read;
    da_Pm_Poll Pm_Poll;
    da_Pm_Write Pm_Write;
    da_Pm_WriteShort Pm_WriteShort;
    da_Pm_WriteSysEx Pm_WriteSysEx;

    //From pmutil.h
    da_Pm_QueueCreate Pm_QueueCreate;
    da_Pm_QueueDestroy Pm_QueueDestroy;
    da_Pm_Dequeue Pm_Dequeue;
    da_Pm_Enqueue Pm_Enqueue;
    da_Pm_QueueFull Pm_QueueFull;
    da_Pm_QueueEmpty Pm_QueueEmpty;
    da_Pm_QueuePeek Pm_QueuePeek;
    da_Pm_SetOverflow Pm_SetOverflow;

}

class DerelictPortMidiLoader : SharedLibLoader {
    public this() {
        super(libNames);
    }
    
    protected override void loadSymbols() {
        bindFunc(cast(void**)&Pm_Initialize, "Pm_Initialize");
        bindFunc(cast(void**)&Pm_Terminate, "Pm_Terminate");
        bindFunc(cast(void**)&Pm_HasHostError, "Pm_HasHostError");
        bindFunc(cast(void**)&Pm_GetErrorText, "Pm_GetErrorText");
        bindFunc(cast(void**)&Pm_GetHostErrorText, "Pm_GetHostErrorText");
        bindFunc(cast(void**)&Pm_CountDevices, "Pm_CountDevices");
        bindFunc(cast(void**)&Pm_GetDefaultInputDeviceID, "Pm_GetDefaultInputDeviceID");
        bindFunc(cast(void**)&Pm_GetDefaultOutputDeviceID, "Pm_GetDefaultOutputDeviceID");
        bindFunc(cast(void**)&Pm_GetDeviceInfo, "Pm_GetDeviceInfo");
        bindFunc(cast(void**)&Pm_OpenInput, "Pm_OpenInput");
        bindFunc(cast(void**)&Pm_OpenOutput, "Pm_OpenOutput");
        bindFunc(cast(void**)&Pm_SetFilter, "Pm_SetFilter");
        bindFunc(cast(void**)&Pm_SetChannelMask, "Pm_SetChannelMask");
        bindFunc(cast(void**)&Pm_Abort, "Pm_Abort");
        bindFunc(cast(void**)&Pm_Close, "Pm_Close");
        bindFunc(cast(void**)&Pm_Read, "Pm_Read");
        bindFunc(cast(void**)&Pm_Poll, "Pm_Poll");
        bindFunc(cast(void**)&Pm_Write, "Pm_Write");
        bindFunc(cast(void**)&Pm_WriteShort, "Pm_WriteShort");
        bindFunc(cast(void**)&Pm_WriteSysEx, "Pm_WriteSysEx");

        //From pmutil.h
        bindFunc(cast(void**)&Pm_QueueCreate, "Pm_QueueCreate");
        bindFunc(cast(void**)&Pm_QueueDestroy, "Pm_QueueDestroy");
        bindFunc(cast(void**)&Pm_Dequeue, "Pm_Dequeue");
        bindFunc(cast(void**)&Pm_Enqueue, "Pm_Enqueue");
        bindFunc(cast(void**)&Pm_QueueFull, "Pm_QueueFull");
        bindFunc(cast(void**)&Pm_QueueEmpty, "Pm_QueueEmpty");
        bindFunc(cast(void**)&Pm_QueuePeek, "Pm_QueuePeek");
        bindFunc(cast(void**)&Pm_SetOverflow, "Pm_SetOverflow");
    }
}

__gshared DerelictPortMidiLoader DerelictPortMidi;

shared static this() {
    DerelictPortMidi = new DerelictPortMidiLoader;
}

