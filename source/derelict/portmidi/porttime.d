module derelict.portmidi.porttime;

private {
    import derelict.util.loader;
    import derelict.util.system;

    //Note: On Linux, libportmidi and libporttime are separate libraries.
    //Under Windows, both sets of functions are actually supplied by libPortMidi.dll
    static if(Derelict_OS_Windows)
        enum libNames = "libPortMidi.dll";

    //NOTE: According to the documentation found in /pm_mac/README_MAC.txt,
    //everything is contained in libportmidi.dylib, no mention of a libporttime.dylib
    else static if(Derelict_OS_Mac)
        enum libNames = "libportmidi.dylib, /usr/local/lib/libportmidi.dylib";

    else static if(Derelict_OS_Posix)
        enum libNames = "libporttime.so, /usr/local/lib/libporttime.so";
        
    else
        static assert(0, "Need to implement libporttime libNames for this operating system.");
}

alias PtError = int;

enum : PtError {
    ptNoError = 0,
    ptHostError = -10000,
    ptAlreadyStarted,
    ptAlreadyStopped,
    ptInsufficientMemory
}

alias PtTimestamp = int;
extern(C) nothrow alias PtCallback = void function(PtTimestamp timestamp, void* userData);

extern(C) @nogc nothrow {
    alias da_Pt_Start = PtError function(int resolution, PtCallback callback, void* userData);
    alias da_Pt_Stop = PtError function();
    alias da_Pt_Started = int function();
    alias da_Pt_Time = PtTimestamp function();
    alias da_Pt_Sleep = void function(int duration);
}

__gshared {
    da_Pt_Start Pt_Start;
    da_Pt_Stop Pt_Stop;
    da_Pt_Started Pt_Started;
    da_Pt_Time Pt_Time;
    da_Pt_Sleep Pt_Sleep;
}

class DerelictPortTimeLoader : SharedLibLoader {
    public this() {
        super(libNames);
    }
    
    protected override void loadSymbols() {
        bindFunc(cast(void**)&Pt_Start, "Pt_Start");
        bindFunc(cast(void**)&Pt_Stop, "Pt_Stop");
        bindFunc(cast(void**)&Pt_Started, "Pt_Started");
        bindFunc(cast(void**)&Pt_Time, "Pt_Time");
        bindFunc(cast(void**)&Pt_Sleep, "Pt_Sleep");
    }
}

__gshared DerelictPortTimeLoader DerelictPortTime;

shared static this() {
    DerelictPortTime = new DerelictPortTimeLoader;
}

