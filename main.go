package main

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"time"
	"unsafe"

	"github.com/ziutek/ftdi"
)

/*
#include <libusb.h>
*/
import "C"

func main() {
	if len(os.Args) < 2 {
		log.Fatal("Usage: ftdi-test <file-descriptor>")
	}

	fd, err := strconv.Atoi(os.Args[1])
	if err != nil {
		log.Fatalf("Invalid file descriptor: %v", err)
	}

	// Initialize libusb and wrap the file descriptor
	var ctx *C.libusb_context

	C.libusb_init(&ctx)
	defer C.libusb_exit(ctx)

	var usbHandle *C.libusb_device_handle
	ret := C.libusb_wrap_sys_device(ctx, C.intptr_t(fd), &usbHandle)
	if ret != 0 {
		log.Fatalf("Failed to wrap device: %d", ret)
	}

	// Now use your forked ftdi library
	ftdiDev, err := ftdi.OpenFromHandle(unsafe.Pointer(usbHandle), ftdi.ChannelA)
	if err != nil {
		log.Fatalf("Failed to open FTDI device: %v", err)
	}
	defer ftdiDev.Close()

	fmt.Println("FTDI device opened successfully")

	// Configure the device
	if err := ftdiDev.SetBaudrate(9600); err != nil {
		log.Fatalf("Failed to set baud rate: %v", err)
	}
	fmt.Println("Baud rate: 9600")

	if err := ftdiDev.SetLineProperties(ftdi.DataBits8, ftdi.StopBits1, ftdi.ParityNone); err != nil {
		log.Fatalf("Failed to set line properties: %v", err)
	}
	fmt.Println("Line properties: 8N1")

	if err := ftdiDev.Reset(); err != nil {
		log.Printf("Reset warning: %v", err)
	}

	if err := ftdiDev.PurgeBuffers(); err != nil {
		log.Printf("Purge buffers warning: %v", err)
	}

	// Write data
	dataToSend := "Hello FTDI!\r\n"
	fmt.Printf("\nSending: %s", dataToSend)

	n, err := ftdiDev.WriteString(dataToSend)
	if err != nil {
		log.Fatalf("Write failed: %v", err)
	}
	fmt.Printf("Wrote %d bytes\n", n)

	// Read data
	time.Sleep(100 * time.Millisecond)

	readBuffer := make([]byte, 256)
	fmt.Println("\nReading response...")

	n, err = ftdiDev.Read(readBuffer)
	if err != nil {
		log.Printf("Read error: %v", err)
	} else if n > 0 {
		fmt.Printf("Received %d bytes: %s\n", n, string(readBuffer[:n]))
	}
}
