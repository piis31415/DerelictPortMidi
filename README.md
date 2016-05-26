A dynamic binding to the [PortMidi](http://portmedia.sourceforge.net) library for the D Programming Language.

It is currently designed to be used against PortMidi version 2.1.7, although other versions may work with this as well. So far, not all functions have been tested, so if you have any problems getting it to work, please let me know immediately.
Derelict itself is maintained [seperately](https://github.com/DerelictOrg) and documentation on how to build projects using Derelict packages can be found [here](https://derelictorg.github.io/using.html). 

```D
import derelict.portmidi.portmidi;
import derelict.portmidi.porttime;

void main() {
    // Load the PortMidi and PortTime libraries.
    DerelictPortMidi.load();
    DerelictPortTime.load();
    
    // Initialize PortMidi
    Pm_Initialize();
    
    // Now PortMidi functions can be called.
    ...
}
```
