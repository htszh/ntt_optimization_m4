OPENCM3DIR  = ./libopencm3
OPENCM3NAME = opencm3_stm32f4
OPENCM3FILE = $(OPENCM3DIR)/lib/lib$(OPENCM3NAME).a

TARGET = ntt
LDSCRIPT    = stm32f405x6.ld

PREFIX     ?= arm-none-eabi
CC          = $(PREFIX)-gcc
OBJCOPY     = $(PREFIX)-objcopy

ARCH_FLAGS  = -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16 -flto

DEFINES     = -DSTM32F4

CFLAGS     += -Wall -Wextra -Wimplicit-function-declaration \
              -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes \
              -Wundef -Wshadow \
              -I$(OPENCM3DIR)/include \
			  -fno-common $(ARCH_FLAGS) -MD $(DEFINES) 

LDFLAGS    += --static -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group \
              -T$(LDSCRIPT) -nostartfiles -Wl,--gc-sections \
			  $(ARCH_FLAGS) -L$(OPENCM3DIR)/lib -lm -l$(OPENCM3NAME)


IMPLEMENTATION_SOURCES = $(wildcard ntt_1round/*.c)  $(wildcard ntt_1round/*.S)
#IMPLEMENTATION_HEADERS = $(./)/*.h

$(TARGET).elf: $(IMPLEMENTATION_SOURCES) $(OPENCM3FILE) common/hal-stm32f4.c
	$(CC) -o $@ $(CFLAGS) \
		$(IMPLEMENTATION_SOURCES) common/hal-stm32f4.c $(LDFLAGS)
#CFLAGS=-g -o

# $(TARGET):fastntt.o basemul.o fastinvntt.o ntt.o
# 	$(CC) -o $@ -c $(CFLAGS) $< $(LDFLAGS)

# ntt.o: ipntt.c 
# 	$(CC) -o $@  $(CFLAGS) $< 

# ntt_asm.o: fastntt.S  basemul.S fastinvntt.S
# 	$(CC) -o $@  $(CFLAGS) $<


# $(TARGET):fastntt.o basemul.o fastinvntt.o ipntt.o
# 	$(CC) -o $@ $(CFLAGS) \
# 		$< 
# 		$(LDFLAGS)

# fastntt.o: fastntt.S
# 	$(CC) -o $@ -c $(CFLAGS) $(ARCH_FLAGS) $(LDFLAGS) $<

# basemul.o: basemul.S
# 	$(CC) -o $@ -c $(CFLAGS) $(ARCH_FLAGS) $(LDFLAGS) $<

# fastinvntt.o: fastinvntt.S
# 	$(CC) -o $@ -c $(CFLAGS) $(ARCH_FLAGS) $(LDFLAGS) $<

# hal.o: common/hal-stm32f4.c
# 	$(CC) -c $^ $(ARCH_FLAGS) $(CFLAGS) $@

# ipntt.o:ipntt.c common/hal-stm32f4.c
# 	$(CC) -o $@ -c $(CFLAGS) $(ARCH_FLAGS) $(LDFLAGS) $<

bin:
	$(OBJCOPY) -Obinary $(TARGET).elf $(TARGET).bin

clean:
	$(RM) *.o $(TARGET).*


