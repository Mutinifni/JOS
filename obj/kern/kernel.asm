
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 10 4e 17 f0       	mov    $0xf0174e10,%eax
f010004b:	2d e2 3e 17 f0       	sub    $0xf0173ee2,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 e2 3e 17 f0       	push   $0xf0173ee2
f0100058:	e8 96 3b 00 00       	call   f0103bf3 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 9d 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 a0 40 10 f0       	push   $0xf01040a0
f010006f:	e8 a8 2c 00 00       	call   f0102d1c <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 27 10 00 00       	call   f01010a0 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 3a 28 00 00       	call   f01028b8 <env_init>
	trap_init();
f010007e:	e8 0a 2d 00 00       	call   f0102d8d <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 a3 11 f0       	push   $0xf011a356
f010008d:	e8 f8 29 00 00       	call   f0102a8a <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 48 41 17 f0    	pushl  0xf0174148
f010009b:	e8 fb 2b 00 00       	call   f0102c9b <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 00 4e 17 f0 00 	cmpl   $0x0,0xf0174e00
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 00 4e 17 f0    	mov    %esi,0xf0174e00

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 bb 40 10 f0       	push   $0xf01040bb
f01000ca:	e8 4d 2c 00 00       	call   f0102d1c <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 1d 2c 00 00       	call   f0102cf6 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 60 48 10 f0 	movl   $0xf0104860,(%esp)
f01000e0:	e8 37 2c 00 00       	call   f0102d1c <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 b8 06 00 00       	call   f01007aa <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 d3 40 10 f0       	push   $0xf01040d3
f010010c:	e8 0b 2c 00 00       	call   f0102d1c <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 d9 2b 00 00       	call   f0102cf6 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 60 48 10 f0 	movl   $0xf0104860,(%esp)
f0100124:	e8 f3 2b 00 00       	call   f0102d1c <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 24 41 17 f0    	mov    0xf0174124,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 24 41 17 f0    	mov    %edx,0xf0174124
f010016e:	88 81 20 3f 17 f0    	mov    %al,-0xfe8c0e0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 24 41 17 f0 00 	movl   $0x0,0xf0174124
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f0 00 00 00    	je     f0100291 <kbd_proc_data+0xfe>
f01001a1:	ba 60 00 00 00       	mov    $0x60,%edx
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a9:	3c e0                	cmp    $0xe0,%al
f01001ab:	75 0d                	jne    f01001ba <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001ad:	83 0d 00 3f 17 f0 40 	orl    $0x40,0xf0173f00
		return 0;
f01001b4:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001b9:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ba:	55                   	push   %ebp
f01001bb:	89 e5                	mov    %esp,%ebp
f01001bd:	53                   	push   %ebx
f01001be:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c1:	84 c0                	test   %al,%al
f01001c3:	79 36                	jns    f01001fb <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001c5:	8b 0d 00 3f 17 f0    	mov    0xf0173f00,%ecx
f01001cb:	89 cb                	mov    %ecx,%ebx
f01001cd:	83 e3 40             	and    $0x40,%ebx
f01001d0:	83 e0 7f             	and    $0x7f,%eax
f01001d3:	85 db                	test   %ebx,%ebx
f01001d5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d8:	0f b6 d2             	movzbl %dl,%edx
f01001db:	0f b6 82 40 42 10 f0 	movzbl -0xfefbdc0(%edx),%eax
f01001e2:	83 c8 40             	or     $0x40,%eax
f01001e5:	0f b6 c0             	movzbl %al,%eax
f01001e8:	f7 d0                	not    %eax
f01001ea:	21 c8                	and    %ecx,%eax
f01001ec:	a3 00 3f 17 f0       	mov    %eax,0xf0173f00
		return 0;
f01001f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f6:	e9 9e 00 00 00       	jmp    f0100299 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001fb:	8b 0d 00 3f 17 f0    	mov    0xf0173f00,%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 0d 00 3f 17 f0    	mov    %ecx,0xf0173f00
	}

	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100217:	0f b6 82 40 42 10 f0 	movzbl -0xfefbdc0(%edx),%eax
f010021e:	0b 05 00 3f 17 f0    	or     0xf0173f00,%eax
f0100224:	0f b6 8a 40 41 10 f0 	movzbl -0xfefbec0(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 00 3f 17 f0       	mov    %eax,0xf0173f00

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d 20 41 10 f0 	mov    -0xfefbee0(,%ecx,4),%ecx
f010023e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100242:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100245:	a8 08                	test   $0x8,%al
f0100247:	74 1b                	je     f0100264 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100249:	89 da                	mov    %ebx,%edx
f010024b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024e:	83 f9 19             	cmp    $0x19,%ecx
f0100251:	77 05                	ja     f0100258 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100253:	83 eb 20             	sub    $0x20,%ebx
f0100256:	eb 0c                	jmp    f0100264 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100258:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010025b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010025e:	83 fa 19             	cmp    $0x19,%edx
f0100261:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100264:	f7 d0                	not    %eax
f0100266:	a8 06                	test   $0x6,%al
f0100268:	75 2d                	jne    f0100297 <kbd_proc_data+0x104>
f010026a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100270:	75 25                	jne    f0100297 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100272:	83 ec 0c             	sub    $0xc,%esp
f0100275:	68 ed 40 10 f0       	push   $0xf01040ed
f010027a:	e8 9d 2a 00 00       	call   f0102d1c <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027f:	ba 92 00 00 00       	mov    $0x92,%edx
f0100284:	b8 03 00 00 00       	mov    $0x3,%eax
f0100289:	ee                   	out    %al,(%dx)
f010028a:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028d:	89 d8                	mov    %ebx,%eax
f010028f:	eb 08                	jmp    f0100299 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100291:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100296:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100297:	89 d8                	mov    %ebx,%eax
}
f0100299:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029c:	c9                   	leave  
f010029d:	c3                   	ret    

f010029e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	57                   	push   %edi
f01002a2:	56                   	push   %esi
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 1c             	sub    $0x1c,%esp
f01002a7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a9:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ae:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002b3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b8:	eb 09                	jmp    f01002c3 <cons_putc+0x25>
f01002ba:	89 ca                	mov    %ecx,%edx
f01002bc:	ec                   	in     (%dx),%al
f01002bd:	ec                   	in     (%dx),%al
f01002be:	ec                   	in     (%dx),%al
f01002bf:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002c0:	83 c3 01             	add    $0x1,%ebx
f01002c3:	89 f2                	mov    %esi,%edx
f01002c5:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c6:	a8 20                	test   $0x20,%al
f01002c8:	75 08                	jne    f01002d2 <cons_putc+0x34>
f01002ca:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002d0:	7e e8                	jle    f01002ba <cons_putc+0x1c>
f01002d2:	89 f8                	mov    %edi,%eax
f01002d4:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002dc:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002dd:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e2:	be 79 03 00 00       	mov    $0x379,%esi
f01002e7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002ec:	eb 09                	jmp    f01002f7 <cons_putc+0x59>
f01002ee:	89 ca                	mov    %ecx,%edx
f01002f0:	ec                   	in     (%dx),%al
f01002f1:	ec                   	in     (%dx),%al
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	ec                   	in     (%dx),%al
f01002f4:	83 c3 01             	add    $0x1,%ebx
f01002f7:	89 f2                	mov    %esi,%edx
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100300:	7f 04                	jg     f0100306 <cons_putc+0x68>
f0100302:	84 c0                	test   %al,%al
f0100304:	79 e8                	jns    f01002ee <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100306:	ba 78 03 00 00       	mov    $0x378,%edx
f010030b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010030f:	ee                   	out    %al,(%dx)
f0100310:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100315:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031a:	ee                   	out    %al,(%dx)
f010031b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100320:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100321:	89 fa                	mov    %edi,%edx
f0100323:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100329:	89 f8                	mov    %edi,%eax
f010032b:	80 cc 07             	or     $0x7,%ah
f010032e:	85 d2                	test   %edx,%edx
f0100330:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100333:	89 f8                	mov    %edi,%eax
f0100335:	0f b6 c0             	movzbl %al,%eax
f0100338:	83 f8 09             	cmp    $0x9,%eax
f010033b:	74 74                	je     f01003b1 <cons_putc+0x113>
f010033d:	83 f8 09             	cmp    $0x9,%eax
f0100340:	7f 0a                	jg     f010034c <cons_putc+0xae>
f0100342:	83 f8 08             	cmp    $0x8,%eax
f0100345:	74 14                	je     f010035b <cons_putc+0xbd>
f0100347:	e9 99 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
f010034c:	83 f8 0a             	cmp    $0xa,%eax
f010034f:	74 3a                	je     f010038b <cons_putc+0xed>
f0100351:	83 f8 0d             	cmp    $0xd,%eax
f0100354:	74 3d                	je     f0100393 <cons_putc+0xf5>
f0100356:	e9 8a 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010035b:	0f b7 05 28 41 17 f0 	movzwl 0xf0174128,%eax
f0100362:	66 85 c0             	test   %ax,%ax
f0100365:	0f 84 e6 00 00 00    	je     f0100451 <cons_putc+0x1b3>
			crt_pos--;
f010036b:	83 e8 01             	sub    $0x1,%eax
f010036e:	66 a3 28 41 17 f0    	mov    %ax,0xf0174128
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100374:	0f b7 c0             	movzwl %ax,%eax
f0100377:	66 81 e7 00 ff       	and    $0xff00,%di
f010037c:	83 cf 20             	or     $0x20,%edi
f010037f:	8b 15 2c 41 17 f0    	mov    0xf017412c,%edx
f0100385:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100389:	eb 78                	jmp    f0100403 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038b:	66 83 05 28 41 17 f0 	addw   $0x50,0xf0174128
f0100392:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100393:	0f b7 05 28 41 17 f0 	movzwl 0xf0174128,%eax
f010039a:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a0:	c1 e8 16             	shr    $0x16,%eax
f01003a3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a6:	c1 e0 04             	shl    $0x4,%eax
f01003a9:	66 a3 28 41 17 f0    	mov    %ax,0xf0174128
f01003af:	eb 52                	jmp    f0100403 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b6:	e8 e3 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003bb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c0:	e8 d9 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003c5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ca:	e8 cf fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d4:	e8 c5 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003de:	e8 bb fe ff ff       	call   f010029e <cons_putc>
f01003e3:	eb 1e                	jmp    f0100403 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e5:	0f b7 05 28 41 17 f0 	movzwl 0xf0174128,%eax
f01003ec:	8d 50 01             	lea    0x1(%eax),%edx
f01003ef:	66 89 15 28 41 17 f0 	mov    %dx,0xf0174128
f01003f6:	0f b7 c0             	movzwl %ax,%eax
f01003f9:	8b 15 2c 41 17 f0    	mov    0xf017412c,%edx
f01003ff:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100403:	66 81 3d 28 41 17 f0 	cmpw   $0x7cf,0xf0174128
f010040a:	cf 07 
f010040c:	76 43                	jbe    f0100451 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040e:	a1 2c 41 17 f0       	mov    0xf017412c,%eax
f0100413:	83 ec 04             	sub    $0x4,%esp
f0100416:	68 00 0f 00 00       	push   $0xf00
f010041b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100421:	52                   	push   %edx
f0100422:	50                   	push   %eax
f0100423:	e8 18 38 00 00       	call   f0103c40 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100428:	8b 15 2c 41 17 f0    	mov    0xf017412c,%edx
f010042e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100434:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010043a:	83 c4 10             	add    $0x10,%esp
f010043d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100442:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100445:	39 d0                	cmp    %edx,%eax
f0100447:	75 f4                	jne    f010043d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 28 41 17 f0 	subw   $0x50,0xf0174128
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 30 41 17 f0    	mov    0xf0174130,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 28 41 17 f0 	movzwl 0xf0174128,%ebx
f0100466:	8d 71 01             	lea    0x1(%ecx),%esi
f0100469:	89 d8                	mov    %ebx,%eax
f010046b:	66 c1 e8 08          	shr    $0x8,%ax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
f010047a:	89 d8                	mov    %ebx,%eax
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100482:	5b                   	pop    %ebx
f0100483:	5e                   	pop    %esi
f0100484:	5f                   	pop    %edi
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100487:	80 3d 34 41 17 f0 00 	cmpb   $0x0,0xf0174134
f010048e:	74 11                	je     f01004a1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100490:	55                   	push   %ebp
f0100491:	89 e5                	mov    %esp,%ebp
f0100493:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100496:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f010049b:	e8 b0 fc ff ff       	call   f0100150 <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	f3 c3                	repz ret 

f01004a3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a3:	55                   	push   %ebp
f01004a4:	89 e5                	mov    %esp,%ebp
f01004a6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a9:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004ae:	e8 9d fc ff ff       	call   f0100150 <cons_intr>
}
f01004b3:	c9                   	leave  
f01004b4:	c3                   	ret    

f01004b5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b5:	55                   	push   %ebp
f01004b6:	89 e5                	mov    %esp,%ebp
f01004b8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bb:	e8 c7 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004c0:	e8 de ff ff ff       	call   f01004a3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c5:	a1 20 41 17 f0       	mov    0xf0174120,%eax
f01004ca:	3b 05 24 41 17 f0    	cmp    0xf0174124,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 20 41 17 f0    	mov    %edx,0xf0174120
f01004db:	0f b6 88 20 3f 17 f0 	movzbl -0xfe8c0e0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004e2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ea:	75 11                	jne    f01004fd <cons_getc+0x48>
			cons.rpos = 0;
f01004ec:	c7 05 20 41 17 f0 00 	movl   $0x0,0xf0174120
f01004f3:	00 00 00 
f01004f6:	eb 05                	jmp    f01004fd <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	57                   	push   %edi
f0100503:	56                   	push   %esi
f0100504:	53                   	push   %ebx
f0100505:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100508:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100516:	5a a5 
	if (*cp != 0xA55A) {
f0100518:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100523:	74 11                	je     f0100536 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100525:	c7 05 30 41 17 f0 b4 	movl   $0x3b4,0xf0174130
f010052c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100534:	eb 16                	jmp    f010054c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100536:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053d:	c7 05 30 41 17 f0 d4 	movl   $0x3d4,0xf0174130
f0100544:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100547:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010054c:	8b 3d 30 41 17 f0    	mov    0xf0174130,%edi
f0100552:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100557:	89 fa                	mov    %edi,%edx
f0100559:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055a:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055d:	89 da                	mov    %ebx,%edx
f010055f:	ec                   	in     (%dx),%al
f0100560:	0f b6 c8             	movzbl %al,%ecx
f0100563:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100566:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056b:	89 fa                	mov    %edi,%edx
f010056d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056e:	89 da                	mov    %ebx,%edx
f0100570:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100571:	89 35 2c 41 17 f0    	mov    %esi,0xf017412c
	crt_pos = pos;
f0100577:	0f b6 c0             	movzbl %al,%eax
f010057a:	09 c8                	or     %ecx,%eax
f010057c:	66 a3 28 41 17 f0    	mov    %ax,0xf0174128
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100582:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100587:	b8 00 00 00 00       	mov    $0x0,%eax
f010058c:	89 f2                	mov    %esi,%edx
f010058e:	ee                   	out    %al,(%dx)
f010058f:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100594:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100599:	ee                   	out    %al,(%dx)
f010059a:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059f:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a4:	89 da                	mov    %ebx,%edx
f01005a6:	ee                   	out    %al,(%dx)
f01005a7:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d8:	ec                   	in     (%dx),%al
f01005d9:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005db:	3c ff                	cmp    $0xff,%al
f01005dd:	0f 95 05 34 41 17 f0 	setne  0xf0174134
f01005e4:	89 f2                	mov    %esi,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 da                	mov    %ebx,%edx
f01005e9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005ea:	80 f9 ff             	cmp    $0xff,%cl
f01005ed:	75 10                	jne    f01005ff <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005ef:	83 ec 0c             	sub    $0xc,%esp
f01005f2:	68 f9 40 10 f0       	push   $0xf01040f9
f01005f7:	e8 20 27 00 00       	call   f0102d1c <cprintf>
f01005fc:	83 c4 10             	add    $0x10,%esp
}
f01005ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5f                   	pop    %edi
f0100605:	5d                   	pop    %ebp
f0100606:	c3                   	ret    

f0100607 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100607:	55                   	push   %ebp
f0100608:	89 e5                	mov    %esp,%ebp
f010060a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010060d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100610:	e8 89 fc ff ff       	call   f010029e <cons_putc>
}
f0100615:	c9                   	leave  
f0100616:	c3                   	ret    

f0100617 <getchar>:

int
getchar(void)
{
f0100617:	55                   	push   %ebp
f0100618:	89 e5                	mov    %esp,%ebp
f010061a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010061d:	e8 93 fe ff ff       	call   f01004b5 <cons_getc>
f0100622:	85 c0                	test   %eax,%eax
f0100624:	74 f7                	je     f010061d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100626:	c9                   	leave  
f0100627:	c3                   	ret    

f0100628 <iscons>:

int
iscons(int fdnum)
{
f0100628:	55                   	push   %ebp
f0100629:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010062b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100630:	5d                   	pop    %ebp
f0100631:	c3                   	ret    

f0100632 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
f0100635:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100638:	68 40 43 10 f0       	push   $0xf0104340
f010063d:	68 5e 43 10 f0       	push   $0xf010435e
f0100642:	68 63 43 10 f0       	push   $0xf0104363
f0100647:	e8 d0 26 00 00       	call   f0102d1c <cprintf>
f010064c:	83 c4 0c             	add    $0xc,%esp
f010064f:	68 dc 43 10 f0       	push   $0xf01043dc
f0100654:	68 6c 43 10 f0       	push   $0xf010436c
f0100659:	68 63 43 10 f0       	push   $0xf0104363
f010065e:	e8 b9 26 00 00       	call   f0102d1c <cprintf>
	return 0;
}
f0100663:	b8 00 00 00 00       	mov    $0x0,%eax
f0100668:	c9                   	leave  
f0100669:	c3                   	ret    

f010066a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010066a:	55                   	push   %ebp
f010066b:	89 e5                	mov    %esp,%ebp
f010066d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100670:	68 75 43 10 f0       	push   $0xf0104375
f0100675:	e8 a2 26 00 00       	call   f0102d1c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067a:	83 c4 08             	add    $0x8,%esp
f010067d:	68 0c 00 10 00       	push   $0x10000c
f0100682:	68 04 44 10 f0       	push   $0xf0104404
f0100687:	e8 90 26 00 00       	call   f0102d1c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068c:	83 c4 0c             	add    $0xc,%esp
f010068f:	68 0c 00 10 00       	push   $0x10000c
f0100694:	68 0c 00 10 f0       	push   $0xf010000c
f0100699:	68 2c 44 10 f0       	push   $0xf010442c
f010069e:	e8 79 26 00 00       	call   f0102d1c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a3:	83 c4 0c             	add    $0xc,%esp
f01006a6:	68 81 40 10 00       	push   $0x104081
f01006ab:	68 81 40 10 f0       	push   $0xf0104081
f01006b0:	68 50 44 10 f0       	push   $0xf0104450
f01006b5:	e8 62 26 00 00       	call   f0102d1c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ba:	83 c4 0c             	add    $0xc,%esp
f01006bd:	68 e2 3e 17 00       	push   $0x173ee2
f01006c2:	68 e2 3e 17 f0       	push   $0xf0173ee2
f01006c7:	68 74 44 10 f0       	push   $0xf0104474
f01006cc:	e8 4b 26 00 00       	call   f0102d1c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d1:	83 c4 0c             	add    $0xc,%esp
f01006d4:	68 10 4e 17 00       	push   $0x174e10
f01006d9:	68 10 4e 17 f0       	push   $0xf0174e10
f01006de:	68 98 44 10 f0       	push   $0xf0104498
f01006e3:	e8 34 26 00 00       	call   f0102d1c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e8:	b8 0f 52 17 f0       	mov    $0xf017520f,%eax
f01006ed:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006f2:	83 c4 08             	add    $0x8,%esp
f01006f5:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006fa:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100700:	85 c0                	test   %eax,%eax
f0100702:	0f 48 c2             	cmovs  %edx,%eax
f0100705:	c1 f8 0a             	sar    $0xa,%eax
f0100708:	50                   	push   %eax
f0100709:	68 bc 44 10 f0       	push   $0xf01044bc
f010070e:	e8 09 26 00 00       	call   f0102d1c <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100713:	b8 00 00 00 00       	mov    $0x0,%eax
f0100718:	c9                   	leave  
f0100719:	c3                   	ret    

f010071a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010071a:	55                   	push   %ebp
f010071b:	89 e5                	mov    %esp,%ebp
f010071d:	57                   	push   %edi
f010071e:	56                   	push   %esi
f010071f:	53                   	push   %ebx
f0100720:	83 ec 58             	sub    $0x58,%esp
	// Your code here.
    cprintf("Stack backtrace:\n");
f0100723:	68 8e 43 10 f0       	push   $0xf010438e
f0100728:	e8 ef 25 00 00       	call   f0102d1c <cprintf>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010072d:	89 e8                	mov    %ebp,%eax

    uint32_t *ebp = (uint32_t *)read_ebp();
f010072f:	89 c6                	mov    %eax,%esi
    while (ebp) {
f0100731:	83 c4 10             	add    $0x10,%esp
f0100734:	eb 63                	jmp    f0100799 <mon_backtrace+0x7f>
        uint32_t old_ebp = ebp[0];
f0100736:	8b 06                	mov    (%esi),%eax
f0100738:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        uint32_t ret_addr = ebp[1];
f010073b:	8b 5e 04             	mov    0x4(%esi),%ebx
        uint32_t arg0 = ebp[2];
f010073e:	8b 56 08             	mov    0x8(%esi),%edx
f0100741:	89 55 c0             	mov    %edx,-0x40(%ebp)
        uint32_t arg1 = ebp[3];
f0100744:	8b 4e 0c             	mov    0xc(%esi),%ecx
f0100747:	89 4d bc             	mov    %ecx,-0x44(%ebp)
        uint32_t arg2 = ebp[4];
f010074a:	8b 7e 10             	mov    0x10(%esi),%edi
f010074d:	89 7d b8             	mov    %edi,-0x48(%ebp)
        uint32_t arg3 = ebp[5];
f0100750:	8b 46 14             	mov    0x14(%esi),%eax
f0100753:	89 45 b4             	mov    %eax,-0x4c(%ebp)
        uint32_t arg4 = ebp[6];
f0100756:	8b 7e 18             	mov    0x18(%esi),%edi

        struct Eipdebuginfo info;
        debuginfo_eip(ret_addr, &info);
f0100759:	83 ec 08             	sub    $0x8,%esp
f010075c:	8d 55 d0             	lea    -0x30(%ebp),%edx
f010075f:	52                   	push   %edx
f0100760:	53                   	push   %ebx
f0100761:	e8 6a 2a 00 00       	call   f01031d0 <debuginfo_eip>

        cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n"
f0100766:	89 d8                	mov    %ebx,%eax
f0100768:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010076b:	89 04 24             	mov    %eax,(%esp)
f010076e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100771:	ff 75 dc             	pushl  -0x24(%ebp)
f0100774:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100777:	ff 75 d0             	pushl  -0x30(%ebp)
f010077a:	57                   	push   %edi
f010077b:	ff 75 b4             	pushl  -0x4c(%ebp)
f010077e:	ff 75 b8             	pushl  -0x48(%ebp)
f0100781:	ff 75 bc             	pushl  -0x44(%ebp)
f0100784:	ff 75 c0             	pushl  -0x40(%ebp)
f0100787:	53                   	push   %ebx
f0100788:	56                   	push   %esi
f0100789:	68 e8 44 10 f0       	push   $0xf01044e8
f010078e:	e8 89 25 00 00       	call   f0102d1c <cprintf>
                info.eip_line,
                info.eip_fn_namelen,
                info.eip_fn_name,
                ret_addr - info.eip_fn_addr);

        ebp = (uint32_t *)old_ebp;
f0100793:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0100796:	83 c4 40             	add    $0x40,%esp
{
	// Your code here.
    cprintf("Stack backtrace:\n");

    uint32_t *ebp = (uint32_t *)read_ebp();
    while (ebp) {
f0100799:	85 f6                	test   %esi,%esi
f010079b:	75 99                	jne    f0100736 <mon_backtrace+0x1c>

        ebp = (uint32_t *)old_ebp;
    }

	return 0;
}
f010079d:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007a5:	5b                   	pop    %ebx
f01007a6:	5e                   	pop    %esi
f01007a7:	5f                   	pop    %edi
f01007a8:	5d                   	pop    %ebp
f01007a9:	c3                   	ret    

f01007aa <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007aa:	55                   	push   %ebp
f01007ab:	89 e5                	mov    %esp,%ebp
f01007ad:	57                   	push   %edi
f01007ae:	56                   	push   %esi
f01007af:	53                   	push   %ebx
f01007b0:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007b3:	68 38 45 10 f0       	push   $0xf0104538
f01007b8:	e8 5f 25 00 00       	call   f0102d1c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007bd:	c7 04 24 5c 45 10 f0 	movl   $0xf010455c,(%esp)
f01007c4:	e8 53 25 00 00       	call   f0102d1c <cprintf>

	if (tf != NULL)
f01007c9:	83 c4 10             	add    $0x10,%esp
f01007cc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007d0:	74 0e                	je     f01007e0 <monitor+0x36>
		print_trapframe(tf);
f01007d2:	83 ec 0c             	sub    $0xc,%esp
f01007d5:	ff 75 08             	pushl  0x8(%ebp)
f01007d8:	e8 48 26 00 00       	call   f0102e25 <print_trapframe>
f01007dd:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007e0:	83 ec 0c             	sub    $0xc,%esp
f01007e3:	68 a0 43 10 f0       	push   $0xf01043a0
f01007e8:	e8 af 31 00 00       	call   f010399c <readline>
f01007ed:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007ef:	83 c4 10             	add    $0x10,%esp
f01007f2:	85 c0                	test   %eax,%eax
f01007f4:	74 ea                	je     f01007e0 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007f6:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007fd:	be 00 00 00 00       	mov    $0x0,%esi
f0100802:	eb 0a                	jmp    f010080e <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100804:	c6 03 00             	movb   $0x0,(%ebx)
f0100807:	89 f7                	mov    %esi,%edi
f0100809:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010080c:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010080e:	0f b6 03             	movzbl (%ebx),%eax
f0100811:	84 c0                	test   %al,%al
f0100813:	74 63                	je     f0100878 <monitor+0xce>
f0100815:	83 ec 08             	sub    $0x8,%esp
f0100818:	0f be c0             	movsbl %al,%eax
f010081b:	50                   	push   %eax
f010081c:	68 a4 43 10 f0       	push   $0xf01043a4
f0100821:	e8 90 33 00 00       	call   f0103bb6 <strchr>
f0100826:	83 c4 10             	add    $0x10,%esp
f0100829:	85 c0                	test   %eax,%eax
f010082b:	75 d7                	jne    f0100804 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f010082d:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100830:	74 46                	je     f0100878 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100832:	83 fe 0f             	cmp    $0xf,%esi
f0100835:	75 14                	jne    f010084b <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100837:	83 ec 08             	sub    $0x8,%esp
f010083a:	6a 10                	push   $0x10
f010083c:	68 a9 43 10 f0       	push   $0xf01043a9
f0100841:	e8 d6 24 00 00       	call   f0102d1c <cprintf>
f0100846:	83 c4 10             	add    $0x10,%esp
f0100849:	eb 95                	jmp    f01007e0 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010084b:	8d 7e 01             	lea    0x1(%esi),%edi
f010084e:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100852:	eb 03                	jmp    f0100857 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100854:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100857:	0f b6 03             	movzbl (%ebx),%eax
f010085a:	84 c0                	test   %al,%al
f010085c:	74 ae                	je     f010080c <monitor+0x62>
f010085e:	83 ec 08             	sub    $0x8,%esp
f0100861:	0f be c0             	movsbl %al,%eax
f0100864:	50                   	push   %eax
f0100865:	68 a4 43 10 f0       	push   $0xf01043a4
f010086a:	e8 47 33 00 00       	call   f0103bb6 <strchr>
f010086f:	83 c4 10             	add    $0x10,%esp
f0100872:	85 c0                	test   %eax,%eax
f0100874:	74 de                	je     f0100854 <monitor+0xaa>
f0100876:	eb 94                	jmp    f010080c <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100878:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010087f:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100880:	85 f6                	test   %esi,%esi
f0100882:	0f 84 58 ff ff ff    	je     f01007e0 <monitor+0x36>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100888:	83 ec 08             	sub    $0x8,%esp
f010088b:	68 5e 43 10 f0       	push   $0xf010435e
f0100890:	ff 75 a8             	pushl  -0x58(%ebp)
f0100893:	e8 c0 32 00 00       	call   f0103b58 <strcmp>
f0100898:	83 c4 10             	add    $0x10,%esp
f010089b:	85 c0                	test   %eax,%eax
f010089d:	74 1e                	je     f01008bd <monitor+0x113>
f010089f:	83 ec 08             	sub    $0x8,%esp
f01008a2:	68 6c 43 10 f0       	push   $0xf010436c
f01008a7:	ff 75 a8             	pushl  -0x58(%ebp)
f01008aa:	e8 a9 32 00 00       	call   f0103b58 <strcmp>
f01008af:	83 c4 10             	add    $0x10,%esp
f01008b2:	85 c0                	test   %eax,%eax
f01008b4:	75 2f                	jne    f01008e5 <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01008bb:	eb 05                	jmp    f01008c2 <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008bd:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008c2:	83 ec 04             	sub    $0x4,%esp
f01008c5:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008c8:	01 d0                	add    %edx,%eax
f01008ca:	ff 75 08             	pushl  0x8(%ebp)
f01008cd:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008d0:	51                   	push   %ecx
f01008d1:	56                   	push   %esi
f01008d2:	ff 14 85 8c 45 10 f0 	call   *-0xfefba74(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008d9:	83 c4 10             	add    $0x10,%esp
f01008dc:	85 c0                	test   %eax,%eax
f01008de:	78 1d                	js     f01008fd <monitor+0x153>
f01008e0:	e9 fb fe ff ff       	jmp    f01007e0 <monitor+0x36>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008e5:	83 ec 08             	sub    $0x8,%esp
f01008e8:	ff 75 a8             	pushl  -0x58(%ebp)
f01008eb:	68 c6 43 10 f0       	push   $0xf01043c6
f01008f0:	e8 27 24 00 00       	call   f0102d1c <cprintf>
f01008f5:	83 c4 10             	add    $0x10,%esp
f01008f8:	e9 e3 fe ff ff       	jmp    f01007e0 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008fd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100900:	5b                   	pop    %ebx
f0100901:	5e                   	pop    %esi
f0100902:	5f                   	pop    %edi
f0100903:	5d                   	pop    %ebp
f0100904:	c3                   	ret    

f0100905 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100905:	83 3d 38 41 17 f0 00 	cmpl   $0x0,0xf0174138
f010090c:	75 11                	jne    f010091f <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010090e:	ba 0f 5e 17 f0       	mov    $0xf0175e0f,%edx
f0100913:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100919:	89 15 38 41 17 f0    	mov    %edx,0xf0174138
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	if (n == 0) {
f010091f:	85 c0                	test   %eax,%eax
f0100921:	75 06                	jne    f0100929 <boot_alloc+0x24>
		result = nextfree;
f0100923:	a1 38 41 17 f0       	mov    0xf0174138,%eax
		return result;
f0100928:	c3                   	ret    
	}

	else {
		result = nextfree;
f0100929:	8b 15 38 41 17 f0    	mov    0xf0174138,%edx
		nextfree += n;
		nextfree = ROUNDUP((char *) nextfree, PGSIZE);
f010092f:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100936:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010093b:	a3 38 41 17 f0       	mov    %eax,0xf0174138
		if((void *) nextfree > (KERNBASE + UTEMP)) {
f0100940:	3d 00 00 40 f0       	cmp    $0xf0400000,%eax
f0100945:	76 17                	jbe    f010095e <boot_alloc+0x59>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100947:	55                   	push   %ebp
f0100948:	89 e5                	mov    %esp,%ebp
f010094a:	83 ec 0c             	sub    $0xc,%esp
	else {
		result = nextfree;
		nextfree += n;
		nextfree = ROUNDUP((char *) nextfree, PGSIZE);
		if((void *) nextfree > (KERNBASE + UTEMP)) {
			panic("not enough memory\n");
f010094d:	68 9c 45 10 f0       	push   $0xf010459c
f0100952:	6a 71                	push   $0x71
f0100954:	68 af 45 10 f0       	push   $0xf01045af
f0100959:	e8 42 f7 ff ff       	call   f01000a0 <_panic>
			return NULL;
		}
		return result;
f010095e:	89 d0                	mov    %edx,%eax
	}

	return NULL;
}
f0100960:	c3                   	ret    

f0100961 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100961:	89 d1                	mov    %edx,%ecx
f0100963:	c1 e9 16             	shr    $0x16,%ecx
f0100966:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100969:	a8 01                	test   $0x1,%al
f010096b:	74 52                	je     f01009bf <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010096d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100972:	89 c1                	mov    %eax,%ecx
f0100974:	c1 e9 0c             	shr    $0xc,%ecx
f0100977:	3b 0d 04 4e 17 f0    	cmp    0xf0174e04,%ecx
f010097d:	72 1b                	jb     f010099a <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010097f:	55                   	push   %ebp
f0100980:	89 e5                	mov    %esp,%ebp
f0100982:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100985:	50                   	push   %eax
f0100986:	68 94 48 10 f0       	push   $0xf0104894
f010098b:	68 35 03 00 00       	push   $0x335
f0100990:	68 af 45 10 f0       	push   $0xf01045af
f0100995:	e8 06 f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010099a:	c1 ea 0c             	shr    $0xc,%edx
f010099d:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009a3:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009aa:	89 c2                	mov    %eax,%edx
f01009ac:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009af:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009b4:	85 d2                	test   %edx,%edx
f01009b6:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009bb:	0f 44 c2             	cmove  %edx,%eax
f01009be:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009c4:	c3                   	ret    

f01009c5 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009c5:	55                   	push   %ebp
f01009c6:	89 e5                	mov    %esp,%ebp
f01009c8:	57                   	push   %edi
f01009c9:	56                   	push   %esi
f01009ca:	53                   	push   %ebx
f01009cb:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009ce:	84 c0                	test   %al,%al
f01009d0:	0f 85 72 02 00 00    	jne    f0100c48 <check_page_free_list+0x283>
f01009d6:	e9 7f 02 00 00       	jmp    f0100c5a <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009db:	83 ec 04             	sub    $0x4,%esp
f01009de:	68 b8 48 10 f0       	push   $0xf01048b8
f01009e3:	68 72 02 00 00       	push   $0x272
f01009e8:	68 af 45 10 f0       	push   $0xf01045af
f01009ed:	e8 ae f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009f2:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009f5:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009f8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009fb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009fe:	89 c2                	mov    %eax,%edx
f0100a00:	2b 15 0c 4e 17 f0    	sub    0xf0174e0c,%edx
f0100a06:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a0c:	0f 95 c2             	setne  %dl
f0100a0f:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a12:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a16:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a18:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a1c:	8b 00                	mov    (%eax),%eax
f0100a1e:	85 c0                	test   %eax,%eax
f0100a20:	75 dc                	jne    f01009fe <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a22:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a25:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a2b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a2e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a31:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a33:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a36:	a3 3c 41 17 f0       	mov    %eax,0xf017413c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a3b:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a40:	8b 1d 3c 41 17 f0    	mov    0xf017413c,%ebx
f0100a46:	eb 53                	jmp    f0100a9b <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a48:	89 d8                	mov    %ebx,%eax
f0100a4a:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f0100a50:	c1 f8 03             	sar    $0x3,%eax
f0100a53:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a56:	89 c2                	mov    %eax,%edx
f0100a58:	c1 ea 16             	shr    $0x16,%edx
f0100a5b:	39 f2                	cmp    %esi,%edx
f0100a5d:	73 3a                	jae    f0100a99 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a5f:	89 c2                	mov    %eax,%edx
f0100a61:	c1 ea 0c             	shr    $0xc,%edx
f0100a64:	3b 15 04 4e 17 f0    	cmp    0xf0174e04,%edx
f0100a6a:	72 12                	jb     f0100a7e <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a6c:	50                   	push   %eax
f0100a6d:	68 94 48 10 f0       	push   $0xf0104894
f0100a72:	6a 56                	push   $0x56
f0100a74:	68 bb 45 10 f0       	push   $0xf01045bb
f0100a79:	e8 22 f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a7e:	83 ec 04             	sub    $0x4,%esp
f0100a81:	68 80 00 00 00       	push   $0x80
f0100a86:	68 97 00 00 00       	push   $0x97
f0100a8b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a90:	50                   	push   %eax
f0100a91:	e8 5d 31 00 00       	call   f0103bf3 <memset>
f0100a96:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a99:	8b 1b                	mov    (%ebx),%ebx
f0100a9b:	85 db                	test   %ebx,%ebx
f0100a9d:	75 a9                	jne    f0100a48 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a9f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aa4:	e8 5c fe ff ff       	call   f0100905 <boot_alloc>
f0100aa9:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aac:	8b 15 3c 41 17 f0    	mov    0xf017413c,%edx
		// check that we didn't corrupt the free list itself
//		cprintf("DONE %x\n", page2pa(pp));
		assert(pp >= pages);
f0100ab2:	8b 0d 0c 4e 17 f0    	mov    0xf0174e0c,%ecx
		assert(pp < pages + npages);
f0100ab8:	a1 04 4e 17 f0       	mov    0xf0174e04,%eax
f0100abd:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ac0:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ac3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ac6:	be 00 00 00 00       	mov    $0x0,%esi
f0100acb:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ace:	e9 30 01 00 00       	jmp    f0100c03 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
//		cprintf("DONE %x\n", page2pa(pp));
		assert(pp >= pages);
f0100ad3:	39 ca                	cmp    %ecx,%edx
f0100ad5:	73 19                	jae    f0100af0 <check_page_free_list+0x12b>
f0100ad7:	68 c9 45 10 f0       	push   $0xf01045c9
f0100adc:	68 d5 45 10 f0       	push   $0xf01045d5
f0100ae1:	68 8d 02 00 00       	push   $0x28d
f0100ae6:	68 af 45 10 f0       	push   $0xf01045af
f0100aeb:	e8 b0 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100af0:	39 fa                	cmp    %edi,%edx
f0100af2:	72 19                	jb     f0100b0d <check_page_free_list+0x148>
f0100af4:	68 ea 45 10 f0       	push   $0xf01045ea
f0100af9:	68 d5 45 10 f0       	push   $0xf01045d5
f0100afe:	68 8e 02 00 00       	push   $0x28e
f0100b03:	68 af 45 10 f0       	push   $0xf01045af
f0100b08:	e8 93 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b0d:	89 d0                	mov    %edx,%eax
f0100b0f:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b12:	a8 07                	test   $0x7,%al
f0100b14:	74 19                	je     f0100b2f <check_page_free_list+0x16a>
f0100b16:	68 dc 48 10 f0       	push   $0xf01048dc
f0100b1b:	68 d5 45 10 f0       	push   $0xf01045d5
f0100b20:	68 8f 02 00 00       	push   $0x28f
f0100b25:	68 af 45 10 f0       	push   $0xf01045af
f0100b2a:	e8 71 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b2f:	c1 f8 03             	sar    $0x3,%eax
f0100b32:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b35:	85 c0                	test   %eax,%eax
f0100b37:	75 19                	jne    f0100b52 <check_page_free_list+0x18d>
f0100b39:	68 fe 45 10 f0       	push   $0xf01045fe
f0100b3e:	68 d5 45 10 f0       	push   $0xf01045d5
f0100b43:	68 92 02 00 00       	push   $0x292
f0100b48:	68 af 45 10 f0       	push   $0xf01045af
f0100b4d:	e8 4e f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b52:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b57:	75 19                	jne    f0100b72 <check_page_free_list+0x1ad>
f0100b59:	68 0f 46 10 f0       	push   $0xf010460f
f0100b5e:	68 d5 45 10 f0       	push   $0xf01045d5
f0100b63:	68 93 02 00 00       	push   $0x293
f0100b68:	68 af 45 10 f0       	push   $0xf01045af
f0100b6d:	e8 2e f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b72:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b77:	75 19                	jne    f0100b92 <check_page_free_list+0x1cd>
f0100b79:	68 10 49 10 f0       	push   $0xf0104910
f0100b7e:	68 d5 45 10 f0       	push   $0xf01045d5
f0100b83:	68 94 02 00 00       	push   $0x294
f0100b88:	68 af 45 10 f0       	push   $0xf01045af
f0100b8d:	e8 0e f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b92:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b97:	75 19                	jne    f0100bb2 <check_page_free_list+0x1ed>
f0100b99:	68 28 46 10 f0       	push   $0xf0104628
f0100b9e:	68 d5 45 10 f0       	push   $0xf01045d5
f0100ba3:	68 95 02 00 00       	push   $0x295
f0100ba8:	68 af 45 10 f0       	push   $0xf01045af
f0100bad:	e8 ee f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bb2:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bb7:	76 3f                	jbe    f0100bf8 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bb9:	89 c3                	mov    %eax,%ebx
f0100bbb:	c1 eb 0c             	shr    $0xc,%ebx
f0100bbe:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bc1:	77 12                	ja     f0100bd5 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bc3:	50                   	push   %eax
f0100bc4:	68 94 48 10 f0       	push   $0xf0104894
f0100bc9:	6a 56                	push   $0x56
f0100bcb:	68 bb 45 10 f0       	push   $0xf01045bb
f0100bd0:	e8 cb f4 ff ff       	call   f01000a0 <_panic>
f0100bd5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bda:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bdd:	76 1e                	jbe    f0100bfd <check_page_free_list+0x238>
f0100bdf:	68 34 49 10 f0       	push   $0xf0104934
f0100be4:	68 d5 45 10 f0       	push   $0xf01045d5
f0100be9:	68 96 02 00 00       	push   $0x296
f0100bee:	68 af 45 10 f0       	push   $0xf01045af
f0100bf3:	e8 a8 f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bf8:	83 c6 01             	add    $0x1,%esi
f0100bfb:	eb 04                	jmp    f0100c01 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bfd:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c01:	8b 12                	mov    (%edx),%edx
f0100c03:	85 d2                	test   %edx,%edx
f0100c05:	0f 85 c8 fe ff ff    	jne    f0100ad3 <check_page_free_list+0x10e>
f0100c0b:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c0e:	85 f6                	test   %esi,%esi
f0100c10:	7f 19                	jg     f0100c2b <check_page_free_list+0x266>
f0100c12:	68 42 46 10 f0       	push   $0xf0104642
f0100c17:	68 d5 45 10 f0       	push   $0xf01045d5
f0100c1c:	68 9e 02 00 00       	push   $0x29e
f0100c21:	68 af 45 10 f0       	push   $0xf01045af
f0100c26:	e8 75 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c2b:	85 db                	test   %ebx,%ebx
f0100c2d:	7f 42                	jg     f0100c71 <check_page_free_list+0x2ac>
f0100c2f:	68 54 46 10 f0       	push   $0xf0104654
f0100c34:	68 d5 45 10 f0       	push   $0xf01045d5
f0100c39:	68 9f 02 00 00       	push   $0x29f
f0100c3e:	68 af 45 10 f0       	push   $0xf01045af
f0100c43:	e8 58 f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c48:	a1 3c 41 17 f0       	mov    0xf017413c,%eax
f0100c4d:	85 c0                	test   %eax,%eax
f0100c4f:	0f 85 9d fd ff ff    	jne    f01009f2 <check_page_free_list+0x2d>
f0100c55:	e9 81 fd ff ff       	jmp    f01009db <check_page_free_list+0x16>
f0100c5a:	83 3d 3c 41 17 f0 00 	cmpl   $0x0,0xf017413c
f0100c61:	0f 84 74 fd ff ff    	je     f01009db <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c67:	be 00 04 00 00       	mov    $0x400,%esi
f0100c6c:	e9 cf fd ff ff       	jmp    f0100a40 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c71:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c74:	5b                   	pop    %ebx
f0100c75:	5e                   	pop    %esi
f0100c76:	5f                   	pop    %edi
f0100c77:	5d                   	pop    %ebp
f0100c78:	c3                   	ret    

f0100c79 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c79:	55                   	push   %ebp
f0100c7a:	89 e5                	mov    %esp,%ebp
f0100c7c:	56                   	push   %esi
f0100c7d:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	page_free_list = NULL;
f0100c7e:	c7 05 3c 41 17 f0 00 	movl   $0x0,0xf017413c
f0100c85:	00 00 00 

	//Marking physical page 0
	pages[0].pp_ref = 1;
f0100c88:	a1 0c 4e 17 f0       	mov    0xf0174e0c,%eax
f0100c8d:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100c93:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
//	for (i = 0; i < npages; i++) {
	for (i = 1; i < npages_basemem; i++) {
f0100c99:	8b 35 40 41 17 f0    	mov    0xf0174140,%esi
f0100c9f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ca4:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ca9:	b8 01 00 00 00       	mov    $0x1,%eax
f0100cae:	eb 27                	jmp    f0100cd7 <page_init+0x5e>
		pages[i].pp_ref = 0;
f0100cb0:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100cb7:	89 d1                	mov    %edx,%ecx
f0100cb9:	03 0d 0c 4e 17 f0    	add    0xf0174e0c,%ecx
f0100cbf:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100cc5:	89 19                	mov    %ebx,(%ecx)

	//Marking physical page 0
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;
//	for (i = 0; i < npages; i++) {
	for (i = 1; i < npages_basemem; i++) {
f0100cc7:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = pages+i;
f0100cca:	89 d3                	mov    %edx,%ebx
f0100ccc:	03 1d 0c 4e 17 f0    	add    0xf0174e0c,%ebx
f0100cd2:	ba 01 00 00 00       	mov    $0x1,%edx

	//Marking physical page 0
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;
//	for (i = 0; i < npages; i++) {
	for (i = 1; i < npages_basemem; i++) {
f0100cd7:	39 f0                	cmp    %esi,%eax
f0100cd9:	72 d5                	jb     f0100cb0 <page_init+0x37>
f0100cdb:	84 d2                	test   %dl,%dl
f0100cdd:	74 06                	je     f0100ce5 <page_init+0x6c>
f0100cdf:	89 1d 3c 41 17 f0    	mov    %ebx,0xf017413c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = pages+i;
	}

	for (i = PGNUM(PADDR(boot_alloc(0))); i < npages; i++) {
f0100ce5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cea:	e8 16 fc ff ff       	call   f0100905 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100cef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100cf4:	77 15                	ja     f0100d0b <page_init+0x92>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100cf6:	50                   	push   %eax
f0100cf7:	68 7c 49 10 f0       	push   $0xf010497c
f0100cfc:	68 2d 01 00 00       	push   $0x12d
f0100d01:	68 af 45 10 f0       	push   $0xf01045af
f0100d06:	e8 95 f3 ff ff       	call   f01000a0 <_panic>
f0100d0b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d10:	c1 e8 0c             	shr    $0xc,%eax
f0100d13:	8b 1d 3c 41 17 f0    	mov    0xf017413c,%ebx
f0100d19:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100d20:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d25:	eb 23                	jmp    f0100d4a <page_init+0xd1>
		pages[i].pp_ref = 0;
f0100d27:	89 d1                	mov    %edx,%ecx
f0100d29:	03 0d 0c 4e 17 f0    	add    0xf0174e0c,%ecx
f0100d2f:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100d35:	89 19                	mov    %ebx,(%ecx)
		page_free_list = pages+i;
f0100d37:	89 d3                	mov    %edx,%ebx
f0100d39:	03 1d 0c 4e 17 f0    	add    0xf0174e0c,%ebx
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = pages+i;
	}

	for (i = PGNUM(PADDR(boot_alloc(0))); i < npages; i++) {
f0100d3f:	83 c0 01             	add    $0x1,%eax
f0100d42:	83 c2 08             	add    $0x8,%edx
f0100d45:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100d4a:	3b 05 04 4e 17 f0    	cmp    0xf0174e04,%eax
f0100d50:	72 d5                	jb     f0100d27 <page_init+0xae>
f0100d52:	84 c9                	test   %cl,%cl
f0100d54:	74 06                	je     f0100d5c <page_init+0xe3>
f0100d56:	89 1d 3c 41 17 f0    	mov    %ebx,0xf017413c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = pages+i;
	}
}
f0100d5c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d5f:	5b                   	pop    %ebx
f0100d60:	5e                   	pop    %esi
f0100d61:	5d                   	pop    %ebp
f0100d62:	c3                   	ret    

f0100d63 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d63:	55                   	push   %ebp
f0100d64:	89 e5                	mov    %esp,%ebp
f0100d66:	53                   	push   %ebx
f0100d67:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *result = page_free_list;
f0100d6a:	8b 1d 3c 41 17 f0    	mov    0xf017413c,%ebx

	if (!result)
f0100d70:	85 db                	test   %ebx,%ebx
f0100d72:	74 56                	je     f0100dca <page_alloc+0x67>
		return NULL;

	page_free_list = result->pp_link;
f0100d74:	8b 03                	mov    (%ebx),%eax
f0100d76:	a3 3c 41 17 f0       	mov    %eax,0xf017413c
	if(alloc_flags & ALLOC_ZERO) {
		char *kva = page2kva(result);
		memset(kva, '\0', PGSIZE);
	}

	return result;
f0100d7b:	89 d8                	mov    %ebx,%eax
	if (!result)
		return NULL;

	page_free_list = result->pp_link;

	if(alloc_flags & ALLOC_ZERO) {
f0100d7d:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d81:	74 4c                	je     f0100dcf <page_alloc+0x6c>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d83:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f0100d89:	c1 f8 03             	sar    $0x3,%eax
f0100d8c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d8f:	89 c2                	mov    %eax,%edx
f0100d91:	c1 ea 0c             	shr    $0xc,%edx
f0100d94:	3b 15 04 4e 17 f0    	cmp    0xf0174e04,%edx
f0100d9a:	72 12                	jb     f0100dae <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d9c:	50                   	push   %eax
f0100d9d:	68 94 48 10 f0       	push   $0xf0104894
f0100da2:	6a 56                	push   $0x56
f0100da4:	68 bb 45 10 f0       	push   $0xf01045bb
f0100da9:	e8 f2 f2 ff ff       	call   f01000a0 <_panic>
		char *kva = page2kva(result);
		memset(kva, '\0', PGSIZE);
f0100dae:	83 ec 04             	sub    $0x4,%esp
f0100db1:	68 00 10 00 00       	push   $0x1000
f0100db6:	6a 00                	push   $0x0
f0100db8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dbd:	50                   	push   %eax
f0100dbe:	e8 30 2e 00 00       	call   f0103bf3 <memset>
f0100dc3:	83 c4 10             	add    $0x10,%esp
	}

	return result;
f0100dc6:	89 d8                	mov    %ebx,%eax
f0100dc8:	eb 05                	jmp    f0100dcf <page_alloc+0x6c>
{
	// Fill this function in
	struct PageInfo *result = page_free_list;

	if (!result)
		return NULL;
f0100dca:	b8 00 00 00 00       	mov    $0x0,%eax
		char *kva = page2kva(result);
		memset(kva, '\0', PGSIZE);
	}

	return result;
}
f0100dcf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100dd2:	c9                   	leave  
f0100dd3:	c3                   	ret    

f0100dd4 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100dd4:	55                   	push   %ebp
f0100dd5:	89 e5                	mov    %esp,%ebp
f0100dd7:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	pp->pp_ref = 0;
f0100dda:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	pp->pp_link = page_free_list;
f0100de0:	8b 15 3c 41 17 f0    	mov    0xf017413c,%edx
f0100de6:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100de8:	a3 3c 41 17 f0       	mov    %eax,0xf017413c
}
f0100ded:	5d                   	pop    %ebp
f0100dee:	c3                   	ret    

f0100def <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100def:	55                   	push   %ebp
f0100df0:	89 e5                	mov    %esp,%ebp
f0100df2:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100df5:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100df9:	83 e8 01             	sub    $0x1,%eax
f0100dfc:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e00:	66 85 c0             	test   %ax,%ax
f0100e03:	75 09                	jne    f0100e0e <page_decref+0x1f>
		page_free(pp);
f0100e05:	52                   	push   %edx
f0100e06:	e8 c9 ff ff ff       	call   f0100dd4 <page_free>
f0100e0b:	83 c4 04             	add    $0x4,%esp
}
f0100e0e:	c9                   	leave  
f0100e0f:	c3                   	ret    

f0100e10 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e10:	55                   	push   %ebp
f0100e11:	89 e5                	mov    %esp,%ebp
f0100e13:	56                   	push   %esi
f0100e14:	53                   	push   %ebx
f0100e15:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *temp;
	struct PageInfo *temp2;

	temp = pgdir + PDX(va);
f0100e18:	89 de                	mov    %ebx,%esi
f0100e1a:	c1 ee 16             	shr    $0x16,%esi
f0100e1d:	c1 e6 02             	shl    $0x2,%esi
f0100e20:	03 75 08             	add    0x8(%ebp),%esi

	if((*temp & PTE_P ) == 0) {
f0100e23:	8b 06                	mov    (%esi),%eax
f0100e25:	a8 01                	test   $0x1,%al
f0100e27:	75 70                	jne    f0100e99 <pgdir_walk+0x89>

		if(!create)
f0100e29:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e2d:	0f 84 a1 00 00 00    	je     f0100ed4 <pgdir_walk+0xc4>
			return NULL;

		else {
			temp2 = page_alloc(ALLOC_ZERO);
f0100e33:	83 ec 0c             	sub    $0xc,%esp
f0100e36:	6a 01                	push   $0x1
f0100e38:	e8 26 ff ff ff       	call   f0100d63 <page_alloc>

			if(temp2 == NULL)
f0100e3d:	83 c4 10             	add    $0x10,%esp
f0100e40:	85 c0                	test   %eax,%eax
f0100e42:	0f 84 93 00 00 00    	je     f0100edb <pgdir_walk+0xcb>
				return NULL;

			else {
				*temp = page2pa(temp2) | PTE_P | PTE_W | PTE_U;
f0100e48:	89 c2                	mov    %eax,%edx
f0100e4a:	2b 15 0c 4e 17 f0    	sub    0xf0174e0c,%edx
f0100e50:	c1 fa 03             	sar    $0x3,%edx
f0100e53:	c1 e2 0c             	shl    $0xc,%edx
f0100e56:	83 ca 07             	or     $0x7,%edx
f0100e59:	89 16                	mov    %edx,(%esi)
				temp2->pp_ref++;
f0100e5b:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
				temp2->pp_link = NULL;
f0100e60:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e66:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f0100e6c:	c1 f8 03             	sar    $0x3,%eax
f0100e6f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e72:	89 c2                	mov    %eax,%edx
f0100e74:	c1 ea 0c             	shr    $0xc,%edx
f0100e77:	3b 15 04 4e 17 f0    	cmp    0xf0174e04,%edx
f0100e7d:	72 12                	jb     f0100e91 <pgdir_walk+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e7f:	50                   	push   %eax
f0100e80:	68 94 48 10 f0       	push   $0xf0104894
f0100e85:	6a 56                	push   $0x56
f0100e87:	68 bb 45 10 f0       	push   $0xf01045bb
f0100e8c:	e8 0f f2 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100e91:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100e97:	eb 2d                	jmp    f0100ec6 <pgdir_walk+0xb6>
			}
		}
	}

	else
		temp = KADDR(PTE_ADDR(*temp));
f0100e99:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e9e:	89 c2                	mov    %eax,%edx
f0100ea0:	c1 ea 0c             	shr    $0xc,%edx
f0100ea3:	3b 15 04 4e 17 f0    	cmp    0xf0174e04,%edx
f0100ea9:	72 15                	jb     f0100ec0 <pgdir_walk+0xb0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eab:	50                   	push   %eax
f0100eac:	68 94 48 10 f0       	push   $0xf0104894
f0100eb1:	68 a1 01 00 00       	push   $0x1a1
f0100eb6:	68 af 45 10 f0       	push   $0xf01045af
f0100ebb:	e8 e0 f1 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100ec0:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx

	return &temp[PTX(va)];
f0100ec6:	c1 eb 0a             	shr    $0xa,%ebx
f0100ec9:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100ecf:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f0100ed2:	eb 0c                	jmp    f0100ee0 <pgdir_walk+0xd0>
	temp = pgdir + PDX(va);

	if((*temp & PTE_P ) == 0) {

		if(!create)
			return NULL;
f0100ed4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ed9:	eb 05                	jmp    f0100ee0 <pgdir_walk+0xd0>

		else {
			temp2 = page_alloc(ALLOC_ZERO);

			if(temp2 == NULL)
				return NULL;
f0100edb:	b8 00 00 00 00       	mov    $0x0,%eax

	else
		temp = KADDR(PTE_ADDR(*temp));

	return &temp[PTX(va)];
}
f0100ee0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ee3:	5b                   	pop    %ebx
f0100ee4:	5e                   	pop    %esi
f0100ee5:	5d                   	pop    %ebp
f0100ee6:	c3                   	ret    

f0100ee7 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100ee7:	55                   	push   %ebp
f0100ee8:	89 e5                	mov    %esp,%ebp
f0100eea:	57                   	push   %edi
f0100eeb:	56                   	push   %esi
f0100eec:	53                   	push   %ebx
f0100eed:	83 ec 1c             	sub    $0x1c,%esp
f0100ef0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ef3:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100ef9:	8d 04 11             	lea    (%ecx,%edx,1),%eax
f0100efc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	// Fill this function in
	while(size >= PGSIZE) {
f0100eff:	89 d3                	mov    %edx,%ebx
f0100f01:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f04:	29 d7                	sub    %edx,%edi
		pte_t *temp;
		temp = pgdir_walk(pgdir, (void *)va, 1);

		if(temp)
			*temp = pa | perm | PTE_P;
f0100f06:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f09:	83 c8 01             	or     $0x1,%eax
f0100f0c:	89 45 dc             	mov    %eax,-0x24(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	while(size >= PGSIZE) {
f0100f0f:	eb 20                	jmp    f0100f31 <boot_map_region+0x4a>
		pte_t *temp;
		temp = pgdir_walk(pgdir, (void *)va, 1);
f0100f11:	83 ec 04             	sub    $0x4,%esp
f0100f14:	6a 01                	push   $0x1
f0100f16:	53                   	push   %ebx
f0100f17:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f1a:	e8 f1 fe ff ff       	call   f0100e10 <pgdir_walk>

		if(temp)
f0100f1f:	83 c4 10             	add    $0x10,%esp
f0100f22:	85 c0                	test   %eax,%eax
f0100f24:	74 05                	je     f0100f2b <boot_map_region+0x44>
			*temp = pa | perm | PTE_P;
f0100f26:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100f29:	89 30                	mov    %esi,(%eax)

		va += PGSIZE;
f0100f2b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f31:	8d 34 1f             	lea    (%edi,%ebx,1),%esi
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	while(size >= PGSIZE) {
f0100f34:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0100f37:	75 d8                	jne    f0100f11 <boot_map_region+0x2a>

		va += PGSIZE;
		pa += PGSIZE;
		size -= PGSIZE;
	}
}
f0100f39:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f3c:	5b                   	pop    %ebx
f0100f3d:	5e                   	pop    %esi
f0100f3e:	5f                   	pop    %edi
f0100f3f:	5d                   	pop    %ebp
f0100f40:	c3                   	ret    

f0100f41 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f41:	55                   	push   %ebp
f0100f42:	89 e5                	mov    %esp,%ebp
f0100f44:	53                   	push   %ebx
f0100f45:	83 ec 08             	sub    $0x8,%esp
f0100f48:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 0);
f0100f4b:	6a 00                	push   $0x0
f0100f4d:	ff 75 0c             	pushl  0xc(%ebp)
f0100f50:	ff 75 08             	pushl  0x8(%ebp)
f0100f53:	e8 b8 fe ff ff       	call   f0100e10 <pgdir_walk>

	if(pte_store)
f0100f58:	83 c4 10             	add    $0x10,%esp
f0100f5b:	85 db                	test   %ebx,%ebx
f0100f5d:	74 02                	je     f0100f61 <page_lookup+0x20>
		*pte_store = pte;
f0100f5f:	89 03                	mov    %eax,(%ebx)

	if(!pte || !(*pte & PTE_P))
f0100f61:	85 c0                	test   %eax,%eax
f0100f63:	74 30                	je     f0100f95 <page_lookup+0x54>
f0100f65:	8b 00                	mov    (%eax),%eax
f0100f67:	a8 01                	test   $0x1,%al
f0100f69:	74 31                	je     f0100f9c <page_lookup+0x5b>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f6b:	c1 e8 0c             	shr    $0xc,%eax
f0100f6e:	3b 05 04 4e 17 f0    	cmp    0xf0174e04,%eax
f0100f74:	72 14                	jb     f0100f8a <page_lookup+0x49>
		panic("pa2page called with invalid pa");
f0100f76:	83 ec 04             	sub    $0x4,%esp
f0100f79:	68 a0 49 10 f0       	push   $0xf01049a0
f0100f7e:	6a 4f                	push   $0x4f
f0100f80:	68 bb 45 10 f0       	push   $0xf01045bb
f0100f85:	e8 16 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100f8a:	8b 15 0c 4e 17 f0    	mov    0xf0174e0c,%edx
f0100f90:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		return NULL;

	return pa2page(PTE_ADDR(*pte));
f0100f93:	eb 0c                	jmp    f0100fa1 <page_lookup+0x60>

	if(pte_store)
		*pte_store = pte;

	if(!pte || !(*pte & PTE_P))
		return NULL;
f0100f95:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f9a:	eb 05                	jmp    f0100fa1 <page_lookup+0x60>
f0100f9c:	b8 00 00 00 00       	mov    $0x0,%eax

	return pa2page(PTE_ADDR(*pte));

}
f0100fa1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fa4:	c9                   	leave  
f0100fa5:	c3                   	ret    

f0100fa6 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fa6:	55                   	push   %ebp
f0100fa7:	89 e5                	mov    %esp,%ebp
f0100fa9:	53                   	push   %ebx
f0100faa:	83 ec 18             	sub    $0x18,%esp
f0100fad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *page;
	page = page_lookup( pgdir, va, &pte );
f0100fb0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fb3:	50                   	push   %eax
f0100fb4:	53                   	push   %ebx
f0100fb5:	ff 75 08             	pushl  0x8(%ebp)
f0100fb8:	e8 84 ff ff ff       	call   f0100f41 <page_lookup>
	if(page) {
f0100fbd:	83 c4 10             	add    $0x10,%esp
f0100fc0:	85 c0                	test   %eax,%eax
f0100fc2:	74 18                	je     f0100fdc <page_remove+0x36>
		page_decref(page);
f0100fc4:	83 ec 0c             	sub    $0xc,%esp
f0100fc7:	50                   	push   %eax
f0100fc8:	e8 22 fe ff ff       	call   f0100def <page_decref>
		*pte = 0;
f0100fcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fd0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fd6:	0f 01 3b             	invlpg (%ebx)
f0100fd9:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}
}
f0100fdc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fdf:	c9                   	leave  
f0100fe0:	c3                   	ret    

f0100fe1 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100fe1:	55                   	push   %ebp
f0100fe2:	89 e5                	mov    %esp,%ebp
f0100fe4:	57                   	push   %edi
f0100fe5:	56                   	push   %esi
f0100fe6:	53                   	push   %ebx
f0100fe7:	83 ec 10             	sub    $0x10,%esp
f0100fea:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100fed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ff0:	8b 75 10             	mov    0x10(%ebp),%esi
	// Fill this function in
	pte_t *temp;
	temp = pgdir_walk(pgdir, va, 1);
f0100ff3:	6a 01                	push   $0x1
f0100ff5:	56                   	push   %esi
f0100ff6:	57                   	push   %edi
f0100ff7:	e8 14 fe ff ff       	call   f0100e10 <pgdir_walk>
	if(!temp)
f0100ffc:	83 c4 10             	add    $0x10,%esp
f0100fff:	85 c0                	test   %eax,%eax
f0101001:	0f 84 8c 00 00 00    	je     f0101093 <page_insert+0xb2>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101007:	8b 10                	mov    (%eax),%edx
f0101009:	c1 ea 0c             	shr    $0xc,%edx
f010100c:	3b 15 04 4e 17 f0    	cmp    0xf0174e04,%edx
f0101012:	72 14                	jb     f0101028 <page_insert+0x47>
		panic("pa2page called with invalid pa");
f0101014:	83 ec 04             	sub    $0x4,%esp
f0101017:	68 a0 49 10 f0       	push   $0xf01049a0
f010101c:	6a 4f                	push   $0x4f
f010101e:	68 bb 45 10 f0       	push   $0xf01045bb
f0101023:	e8 78 f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0101028:	8b 0d 0c 4e 17 f0    	mov    0xf0174e0c,%ecx
		return -E_NO_MEM;
	else if(pa2page(*temp) == pp)
f010102e:	8d 14 d1             	lea    (%ecx,%edx,8),%edx
f0101031:	39 d3                	cmp    %edx,%ebx
f0101033:	75 19                	jne    f010104e <page_insert+0x6d>
		*temp = page2pa(pp) | perm | PTE_P;
f0101035:	29 cb                	sub    %ecx,%ebx
f0101037:	c1 fb 03             	sar    $0x3,%ebx
f010103a:	c1 e3 0c             	shl    $0xc,%ebx
f010103d:	8b 55 14             	mov    0x14(%ebp),%edx
f0101040:	83 ca 01             	or     $0x1,%edx
f0101043:	09 d3                	or     %edx,%ebx
f0101045:	89 18                	mov    %ebx,(%eax)
		tlb_invalidate(pgdir, va);
		boot_map_region(pgdir, (uintptr_t)va, PGSIZE, page2pa(pp), perm);
		pp->pp_ref ++;
		pp->pp_link = NULL;
	}
	return 0;
f0101047:	b8 00 00 00 00       	mov    $0x0,%eax
f010104c:	eb 4a                	jmp    f0101098 <page_insert+0xb7>
	if(!temp)
		return -E_NO_MEM;
	else if(pa2page(*temp) == pp)
		*temp = page2pa(pp) | perm | PTE_P;
	else {
		page_remove(pgdir, va);
f010104e:	83 ec 08             	sub    $0x8,%esp
f0101051:	56                   	push   %esi
f0101052:	57                   	push   %edi
f0101053:	e8 4e ff ff ff       	call   f0100fa6 <page_remove>
f0101058:	0f 01 3e             	invlpg (%esi)
		tlb_invalidate(pgdir, va);
		boot_map_region(pgdir, (uintptr_t)va, PGSIZE, page2pa(pp), perm);
f010105b:	83 c4 08             	add    $0x8,%esp
f010105e:	ff 75 14             	pushl  0x14(%ebp)
f0101061:	89 d8                	mov    %ebx,%eax
f0101063:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f0101069:	c1 f8 03             	sar    $0x3,%eax
f010106c:	c1 e0 0c             	shl    $0xc,%eax
f010106f:	50                   	push   %eax
f0101070:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0101075:	89 f2                	mov    %esi,%edx
f0101077:	89 f8                	mov    %edi,%eax
f0101079:	e8 69 fe ff ff       	call   f0100ee7 <boot_map_region>
		pp->pp_ref ++;
f010107e:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
		pp->pp_link = NULL;
f0101083:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
f0101089:	83 c4 10             	add    $0x10,%esp
	}
	return 0;
f010108c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101091:	eb 05                	jmp    f0101098 <page_insert+0xb7>
{
	// Fill this function in
	pte_t *temp;
	temp = pgdir_walk(pgdir, va, 1);
	if(!temp)
		return -E_NO_MEM;
f0101093:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		boot_map_region(pgdir, (uintptr_t)va, PGSIZE, page2pa(pp), perm);
		pp->pp_ref ++;
		pp->pp_link = NULL;
	}
	return 0;
}
f0101098:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010109b:	5b                   	pop    %ebx
f010109c:	5e                   	pop    %esi
f010109d:	5f                   	pop    %edi
f010109e:	5d                   	pop    %ebp
f010109f:	c3                   	ret    

f01010a0 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010a0:	55                   	push   %ebp
f01010a1:	89 e5                	mov    %esp,%ebp
f01010a3:	57                   	push   %edi
f01010a4:	56                   	push   %esi
f01010a5:	53                   	push   %ebx
f01010a6:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010a9:	6a 15                	push   $0x15
f01010ab:	e8 05 1c 00 00       	call   f0102cb5 <mc146818_read>
f01010b0:	89 c3                	mov    %eax,%ebx
f01010b2:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01010b9:	e8 f7 1b 00 00       	call   f0102cb5 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01010be:	c1 e0 08             	shl    $0x8,%eax
f01010c1:	09 d8                	or     %ebx,%eax
f01010c3:	c1 e0 0a             	shl    $0xa,%eax
f01010c6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010cc:	85 c0                	test   %eax,%eax
f01010ce:	0f 48 c2             	cmovs  %edx,%eax
f01010d1:	c1 f8 0c             	sar    $0xc,%eax
f01010d4:	a3 40 41 17 f0       	mov    %eax,0xf0174140
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010d9:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01010e0:	e8 d0 1b 00 00       	call   f0102cb5 <mc146818_read>
f01010e5:	89 c3                	mov    %eax,%ebx
f01010e7:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01010ee:	e8 c2 1b 00 00       	call   f0102cb5 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01010f3:	c1 e0 08             	shl    $0x8,%eax
f01010f6:	09 d8                	or     %ebx,%eax
f01010f8:	c1 e0 0a             	shl    $0xa,%eax
f01010fb:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101101:	83 c4 10             	add    $0x10,%esp
f0101104:	85 c0                	test   %eax,%eax
f0101106:	0f 48 c2             	cmovs  %edx,%eax
f0101109:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010110c:	85 c0                	test   %eax,%eax
f010110e:	74 0e                	je     f010111e <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101110:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101116:	89 15 04 4e 17 f0    	mov    %edx,0xf0174e04
f010111c:	eb 0c                	jmp    f010112a <mem_init+0x8a>
	else
		npages = npages_basemem;
f010111e:	8b 15 40 41 17 f0    	mov    0xf0174140,%edx
f0101124:	89 15 04 4e 17 f0    	mov    %edx,0xf0174e04

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010112a:	c1 e0 0c             	shl    $0xc,%eax
f010112d:	c1 e8 0a             	shr    $0xa,%eax
f0101130:	50                   	push   %eax
f0101131:	a1 40 41 17 f0       	mov    0xf0174140,%eax
f0101136:	c1 e0 0c             	shl    $0xc,%eax
f0101139:	c1 e8 0a             	shr    $0xa,%eax
f010113c:	50                   	push   %eax
f010113d:	a1 04 4e 17 f0       	mov    0xf0174e04,%eax
f0101142:	c1 e0 0c             	shl    $0xc,%eax
f0101145:	c1 e8 0a             	shr    $0xa,%eax
f0101148:	50                   	push   %eax
f0101149:	68 c0 49 10 f0       	push   $0xf01049c0
f010114e:	e8 c9 1b 00 00       	call   f0102d1c <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101153:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101158:	e8 a8 f7 ff ff       	call   f0100905 <boot_alloc>
f010115d:	a3 08 4e 17 f0       	mov    %eax,0xf0174e08
	memset(kern_pgdir, 0, PGSIZE);
f0101162:	83 c4 0c             	add    $0xc,%esp
f0101165:	68 00 10 00 00       	push   $0x1000
f010116a:	6a 00                	push   $0x0
f010116c:	50                   	push   %eax
f010116d:	e8 81 2a 00 00       	call   f0103bf3 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101172:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101177:	83 c4 10             	add    $0x10,%esp
f010117a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010117f:	77 15                	ja     f0101196 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101181:	50                   	push   %eax
f0101182:	68 7c 49 10 f0       	push   $0xf010497c
f0101187:	68 9b 00 00 00       	push   $0x9b
f010118c:	68 af 45 10 f0       	push   $0xf01045af
f0101191:	e8 0a ef ff ff       	call   f01000a0 <_panic>
f0101196:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010119c:	83 ca 05             	or     $0x5,%edx
f010119f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc (npages * sizeof(struct PageInfo));
f01011a5:	a1 04 4e 17 f0       	mov    0xf0174e04,%eax
f01011aa:	c1 e0 03             	shl    $0x3,%eax
f01011ad:	e8 53 f7 ff ff       	call   f0100905 <boot_alloc>
f01011b2:	a3 0c 4e 17 f0       	mov    %eax,0xf0174e0c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01011b7:	83 ec 04             	sub    $0x4,%esp
f01011ba:	8b 3d 04 4e 17 f0    	mov    0xf0174e04,%edi
f01011c0:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01011c7:	52                   	push   %edx
f01011c8:	6a 00                	push   $0x0
f01011ca:	50                   	push   %eax
f01011cb:	e8 23 2a 00 00       	call   f0103bf3 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc (NENV * sizeof(struct Env));
f01011d0:	b8 00 80 01 00       	mov    $0x18000,%eax
f01011d5:	e8 2b f7 ff ff       	call   f0100905 <boot_alloc>
f01011da:	a3 48 41 17 f0       	mov    %eax,0xf0174148
	memset(envs, 0, NENV * sizeof(struct Env));
f01011df:	83 c4 0c             	add    $0xc,%esp
f01011e2:	68 00 80 01 00       	push   $0x18000
f01011e7:	6a 00                	push   $0x0
f01011e9:	50                   	push   %eax
f01011ea:	e8 04 2a 00 00       	call   f0103bf3 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011ef:	e8 85 fa ff ff       	call   f0100c79 <page_init>

	check_page_free_list(1);
f01011f4:	b8 01 00 00 00       	mov    $0x1,%eax
f01011f9:	e8 c7 f7 ff ff       	call   f01009c5 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011fe:	83 c4 10             	add    $0x10,%esp
f0101201:	83 3d 0c 4e 17 f0 00 	cmpl   $0x0,0xf0174e0c
f0101208:	75 17                	jne    f0101221 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f010120a:	83 ec 04             	sub    $0x4,%esp
f010120d:	68 65 46 10 f0       	push   $0xf0104665
f0101212:	68 b0 02 00 00       	push   $0x2b0
f0101217:	68 af 45 10 f0       	push   $0xf01045af
f010121c:	e8 7f ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101221:	a1 3c 41 17 f0       	mov    0xf017413c,%eax
f0101226:	bb 00 00 00 00       	mov    $0x0,%ebx
f010122b:	eb 05                	jmp    f0101232 <mem_init+0x192>
		++nfree;
f010122d:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101230:	8b 00                	mov    (%eax),%eax
f0101232:	85 c0                	test   %eax,%eax
f0101234:	75 f7                	jne    f010122d <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101236:	83 ec 0c             	sub    $0xc,%esp
f0101239:	6a 00                	push   $0x0
f010123b:	e8 23 fb ff ff       	call   f0100d63 <page_alloc>
f0101240:	89 c7                	mov    %eax,%edi
f0101242:	83 c4 10             	add    $0x10,%esp
f0101245:	85 c0                	test   %eax,%eax
f0101247:	75 19                	jne    f0101262 <mem_init+0x1c2>
f0101249:	68 80 46 10 f0       	push   $0xf0104680
f010124e:	68 d5 45 10 f0       	push   $0xf01045d5
f0101253:	68 b8 02 00 00       	push   $0x2b8
f0101258:	68 af 45 10 f0       	push   $0xf01045af
f010125d:	e8 3e ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101262:	83 ec 0c             	sub    $0xc,%esp
f0101265:	6a 00                	push   $0x0
f0101267:	e8 f7 fa ff ff       	call   f0100d63 <page_alloc>
f010126c:	89 c6                	mov    %eax,%esi
f010126e:	83 c4 10             	add    $0x10,%esp
f0101271:	85 c0                	test   %eax,%eax
f0101273:	75 19                	jne    f010128e <mem_init+0x1ee>
f0101275:	68 96 46 10 f0       	push   $0xf0104696
f010127a:	68 d5 45 10 f0       	push   $0xf01045d5
f010127f:	68 b9 02 00 00       	push   $0x2b9
f0101284:	68 af 45 10 f0       	push   $0xf01045af
f0101289:	e8 12 ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010128e:	83 ec 0c             	sub    $0xc,%esp
f0101291:	6a 00                	push   $0x0
f0101293:	e8 cb fa ff ff       	call   f0100d63 <page_alloc>
f0101298:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010129b:	83 c4 10             	add    $0x10,%esp
f010129e:	85 c0                	test   %eax,%eax
f01012a0:	75 19                	jne    f01012bb <mem_init+0x21b>
f01012a2:	68 ac 46 10 f0       	push   $0xf01046ac
f01012a7:	68 d5 45 10 f0       	push   $0xf01045d5
f01012ac:	68 ba 02 00 00       	push   $0x2ba
f01012b1:	68 af 45 10 f0       	push   $0xf01045af
f01012b6:	e8 e5 ed ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012bb:	39 f7                	cmp    %esi,%edi
f01012bd:	75 19                	jne    f01012d8 <mem_init+0x238>
f01012bf:	68 c2 46 10 f0       	push   $0xf01046c2
f01012c4:	68 d5 45 10 f0       	push   $0xf01045d5
f01012c9:	68 bd 02 00 00       	push   $0x2bd
f01012ce:	68 af 45 10 f0       	push   $0xf01045af
f01012d3:	e8 c8 ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012db:	39 c6                	cmp    %eax,%esi
f01012dd:	74 04                	je     f01012e3 <mem_init+0x243>
f01012df:	39 c7                	cmp    %eax,%edi
f01012e1:	75 19                	jne    f01012fc <mem_init+0x25c>
f01012e3:	68 fc 49 10 f0       	push   $0xf01049fc
f01012e8:	68 d5 45 10 f0       	push   $0xf01045d5
f01012ed:	68 be 02 00 00       	push   $0x2be
f01012f2:	68 af 45 10 f0       	push   $0xf01045af
f01012f7:	e8 a4 ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012fc:	8b 0d 0c 4e 17 f0    	mov    0xf0174e0c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101302:	8b 15 04 4e 17 f0    	mov    0xf0174e04,%edx
f0101308:	c1 e2 0c             	shl    $0xc,%edx
f010130b:	89 f8                	mov    %edi,%eax
f010130d:	29 c8                	sub    %ecx,%eax
f010130f:	c1 f8 03             	sar    $0x3,%eax
f0101312:	c1 e0 0c             	shl    $0xc,%eax
f0101315:	39 d0                	cmp    %edx,%eax
f0101317:	72 19                	jb     f0101332 <mem_init+0x292>
f0101319:	68 d4 46 10 f0       	push   $0xf01046d4
f010131e:	68 d5 45 10 f0       	push   $0xf01045d5
f0101323:	68 bf 02 00 00       	push   $0x2bf
f0101328:	68 af 45 10 f0       	push   $0xf01045af
f010132d:	e8 6e ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101332:	89 f0                	mov    %esi,%eax
f0101334:	29 c8                	sub    %ecx,%eax
f0101336:	c1 f8 03             	sar    $0x3,%eax
f0101339:	c1 e0 0c             	shl    $0xc,%eax
f010133c:	39 c2                	cmp    %eax,%edx
f010133e:	77 19                	ja     f0101359 <mem_init+0x2b9>
f0101340:	68 f1 46 10 f0       	push   $0xf01046f1
f0101345:	68 d5 45 10 f0       	push   $0xf01045d5
f010134a:	68 c0 02 00 00       	push   $0x2c0
f010134f:	68 af 45 10 f0       	push   $0xf01045af
f0101354:	e8 47 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101359:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010135c:	29 c8                	sub    %ecx,%eax
f010135e:	c1 f8 03             	sar    $0x3,%eax
f0101361:	c1 e0 0c             	shl    $0xc,%eax
f0101364:	39 c2                	cmp    %eax,%edx
f0101366:	77 19                	ja     f0101381 <mem_init+0x2e1>
f0101368:	68 0e 47 10 f0       	push   $0xf010470e
f010136d:	68 d5 45 10 f0       	push   $0xf01045d5
f0101372:	68 c1 02 00 00       	push   $0x2c1
f0101377:	68 af 45 10 f0       	push   $0xf01045af
f010137c:	e8 1f ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101381:	a1 3c 41 17 f0       	mov    0xf017413c,%eax
f0101386:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101389:	c7 05 3c 41 17 f0 00 	movl   $0x0,0xf017413c
f0101390:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101393:	83 ec 0c             	sub    $0xc,%esp
f0101396:	6a 00                	push   $0x0
f0101398:	e8 c6 f9 ff ff       	call   f0100d63 <page_alloc>
f010139d:	83 c4 10             	add    $0x10,%esp
f01013a0:	85 c0                	test   %eax,%eax
f01013a2:	74 19                	je     f01013bd <mem_init+0x31d>
f01013a4:	68 2b 47 10 f0       	push   $0xf010472b
f01013a9:	68 d5 45 10 f0       	push   $0xf01045d5
f01013ae:	68 c8 02 00 00       	push   $0x2c8
f01013b3:	68 af 45 10 f0       	push   $0xf01045af
f01013b8:	e8 e3 ec ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01013bd:	83 ec 0c             	sub    $0xc,%esp
f01013c0:	57                   	push   %edi
f01013c1:	e8 0e fa ff ff       	call   f0100dd4 <page_free>
	page_free(pp1);
f01013c6:	89 34 24             	mov    %esi,(%esp)
f01013c9:	e8 06 fa ff ff       	call   f0100dd4 <page_free>
	page_free(pp2);
f01013ce:	83 c4 04             	add    $0x4,%esp
f01013d1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013d4:	e8 fb f9 ff ff       	call   f0100dd4 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013d9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013e0:	e8 7e f9 ff ff       	call   f0100d63 <page_alloc>
f01013e5:	89 c6                	mov    %eax,%esi
f01013e7:	83 c4 10             	add    $0x10,%esp
f01013ea:	85 c0                	test   %eax,%eax
f01013ec:	75 19                	jne    f0101407 <mem_init+0x367>
f01013ee:	68 80 46 10 f0       	push   $0xf0104680
f01013f3:	68 d5 45 10 f0       	push   $0xf01045d5
f01013f8:	68 cf 02 00 00       	push   $0x2cf
f01013fd:	68 af 45 10 f0       	push   $0xf01045af
f0101402:	e8 99 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101407:	83 ec 0c             	sub    $0xc,%esp
f010140a:	6a 00                	push   $0x0
f010140c:	e8 52 f9 ff ff       	call   f0100d63 <page_alloc>
f0101411:	89 c7                	mov    %eax,%edi
f0101413:	83 c4 10             	add    $0x10,%esp
f0101416:	85 c0                	test   %eax,%eax
f0101418:	75 19                	jne    f0101433 <mem_init+0x393>
f010141a:	68 96 46 10 f0       	push   $0xf0104696
f010141f:	68 d5 45 10 f0       	push   $0xf01045d5
f0101424:	68 d0 02 00 00       	push   $0x2d0
f0101429:	68 af 45 10 f0       	push   $0xf01045af
f010142e:	e8 6d ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101433:	83 ec 0c             	sub    $0xc,%esp
f0101436:	6a 00                	push   $0x0
f0101438:	e8 26 f9 ff ff       	call   f0100d63 <page_alloc>
f010143d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101440:	83 c4 10             	add    $0x10,%esp
f0101443:	85 c0                	test   %eax,%eax
f0101445:	75 19                	jne    f0101460 <mem_init+0x3c0>
f0101447:	68 ac 46 10 f0       	push   $0xf01046ac
f010144c:	68 d5 45 10 f0       	push   $0xf01045d5
f0101451:	68 d1 02 00 00       	push   $0x2d1
f0101456:	68 af 45 10 f0       	push   $0xf01045af
f010145b:	e8 40 ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101460:	39 fe                	cmp    %edi,%esi
f0101462:	75 19                	jne    f010147d <mem_init+0x3dd>
f0101464:	68 c2 46 10 f0       	push   $0xf01046c2
f0101469:	68 d5 45 10 f0       	push   $0xf01045d5
f010146e:	68 d3 02 00 00       	push   $0x2d3
f0101473:	68 af 45 10 f0       	push   $0xf01045af
f0101478:	e8 23 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010147d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101480:	39 c7                	cmp    %eax,%edi
f0101482:	74 04                	je     f0101488 <mem_init+0x3e8>
f0101484:	39 c6                	cmp    %eax,%esi
f0101486:	75 19                	jne    f01014a1 <mem_init+0x401>
f0101488:	68 fc 49 10 f0       	push   $0xf01049fc
f010148d:	68 d5 45 10 f0       	push   $0xf01045d5
f0101492:	68 d4 02 00 00       	push   $0x2d4
f0101497:	68 af 45 10 f0       	push   $0xf01045af
f010149c:	e8 ff eb ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01014a1:	83 ec 0c             	sub    $0xc,%esp
f01014a4:	6a 00                	push   $0x0
f01014a6:	e8 b8 f8 ff ff       	call   f0100d63 <page_alloc>
f01014ab:	83 c4 10             	add    $0x10,%esp
f01014ae:	85 c0                	test   %eax,%eax
f01014b0:	74 19                	je     f01014cb <mem_init+0x42b>
f01014b2:	68 2b 47 10 f0       	push   $0xf010472b
f01014b7:	68 d5 45 10 f0       	push   $0xf01045d5
f01014bc:	68 d5 02 00 00       	push   $0x2d5
f01014c1:	68 af 45 10 f0       	push   $0xf01045af
f01014c6:	e8 d5 eb ff ff       	call   f01000a0 <_panic>
f01014cb:	89 f0                	mov    %esi,%eax
f01014cd:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f01014d3:	c1 f8 03             	sar    $0x3,%eax
f01014d6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014d9:	89 c2                	mov    %eax,%edx
f01014db:	c1 ea 0c             	shr    $0xc,%edx
f01014de:	3b 15 04 4e 17 f0    	cmp    0xf0174e04,%edx
f01014e4:	72 12                	jb     f01014f8 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014e6:	50                   	push   %eax
f01014e7:	68 94 48 10 f0       	push   $0xf0104894
f01014ec:	6a 56                	push   $0x56
f01014ee:	68 bb 45 10 f0       	push   $0xf01045bb
f01014f3:	e8 a8 eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014f8:	83 ec 04             	sub    $0x4,%esp
f01014fb:	68 00 10 00 00       	push   $0x1000
f0101500:	6a 01                	push   $0x1
f0101502:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101507:	50                   	push   %eax
f0101508:	e8 e6 26 00 00       	call   f0103bf3 <memset>
	page_free(pp0);
f010150d:	89 34 24             	mov    %esi,(%esp)
f0101510:	e8 bf f8 ff ff       	call   f0100dd4 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101515:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010151c:	e8 42 f8 ff ff       	call   f0100d63 <page_alloc>
f0101521:	83 c4 10             	add    $0x10,%esp
f0101524:	85 c0                	test   %eax,%eax
f0101526:	75 19                	jne    f0101541 <mem_init+0x4a1>
f0101528:	68 3a 47 10 f0       	push   $0xf010473a
f010152d:	68 d5 45 10 f0       	push   $0xf01045d5
f0101532:	68 da 02 00 00       	push   $0x2da
f0101537:	68 af 45 10 f0       	push   $0xf01045af
f010153c:	e8 5f eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f0101541:	39 c6                	cmp    %eax,%esi
f0101543:	74 19                	je     f010155e <mem_init+0x4be>
f0101545:	68 58 47 10 f0       	push   $0xf0104758
f010154a:	68 d5 45 10 f0       	push   $0xf01045d5
f010154f:	68 db 02 00 00       	push   $0x2db
f0101554:	68 af 45 10 f0       	push   $0xf01045af
f0101559:	e8 42 eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010155e:	89 f0                	mov    %esi,%eax
f0101560:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f0101566:	c1 f8 03             	sar    $0x3,%eax
f0101569:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010156c:	89 c2                	mov    %eax,%edx
f010156e:	c1 ea 0c             	shr    $0xc,%edx
f0101571:	3b 15 04 4e 17 f0    	cmp    0xf0174e04,%edx
f0101577:	72 12                	jb     f010158b <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101579:	50                   	push   %eax
f010157a:	68 94 48 10 f0       	push   $0xf0104894
f010157f:	6a 56                	push   $0x56
f0101581:	68 bb 45 10 f0       	push   $0xf01045bb
f0101586:	e8 15 eb ff ff       	call   f01000a0 <_panic>
f010158b:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101591:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101597:	80 38 00             	cmpb   $0x0,(%eax)
f010159a:	74 19                	je     f01015b5 <mem_init+0x515>
f010159c:	68 68 47 10 f0       	push   $0xf0104768
f01015a1:	68 d5 45 10 f0       	push   $0xf01045d5
f01015a6:	68 de 02 00 00       	push   $0x2de
f01015ab:	68 af 45 10 f0       	push   $0xf01045af
f01015b0:	e8 eb ea ff ff       	call   f01000a0 <_panic>
f01015b5:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01015b8:	39 d0                	cmp    %edx,%eax
f01015ba:	75 db                	jne    f0101597 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01015bc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015bf:	a3 3c 41 17 f0       	mov    %eax,0xf017413c

	// free the pages we took
	page_free(pp0);
f01015c4:	83 ec 0c             	sub    $0xc,%esp
f01015c7:	56                   	push   %esi
f01015c8:	e8 07 f8 ff ff       	call   f0100dd4 <page_free>
	page_free(pp1);
f01015cd:	89 3c 24             	mov    %edi,(%esp)
f01015d0:	e8 ff f7 ff ff       	call   f0100dd4 <page_free>
	page_free(pp2);
f01015d5:	83 c4 04             	add    $0x4,%esp
f01015d8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015db:	e8 f4 f7 ff ff       	call   f0100dd4 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015e0:	a1 3c 41 17 f0       	mov    0xf017413c,%eax
f01015e5:	83 c4 10             	add    $0x10,%esp
f01015e8:	eb 05                	jmp    f01015ef <mem_init+0x54f>
		--nfree;
f01015ea:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015ed:	8b 00                	mov    (%eax),%eax
f01015ef:	85 c0                	test   %eax,%eax
f01015f1:	75 f7                	jne    f01015ea <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f01015f3:	85 db                	test   %ebx,%ebx
f01015f5:	74 19                	je     f0101610 <mem_init+0x570>
f01015f7:	68 72 47 10 f0       	push   $0xf0104772
f01015fc:	68 d5 45 10 f0       	push   $0xf01045d5
f0101601:	68 eb 02 00 00       	push   $0x2eb
f0101606:	68 af 45 10 f0       	push   $0xf01045af
f010160b:	e8 90 ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101610:	83 ec 0c             	sub    $0xc,%esp
f0101613:	68 1c 4a 10 f0       	push   $0xf0104a1c
f0101618:	e8 ff 16 00 00       	call   f0102d1c <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010161d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101624:	e8 3a f7 ff ff       	call   f0100d63 <page_alloc>
f0101629:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010162c:	83 c4 10             	add    $0x10,%esp
f010162f:	85 c0                	test   %eax,%eax
f0101631:	75 19                	jne    f010164c <mem_init+0x5ac>
f0101633:	68 80 46 10 f0       	push   $0xf0104680
f0101638:	68 d5 45 10 f0       	push   $0xf01045d5
f010163d:	68 49 03 00 00       	push   $0x349
f0101642:	68 af 45 10 f0       	push   $0xf01045af
f0101647:	e8 54 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010164c:	83 ec 0c             	sub    $0xc,%esp
f010164f:	6a 00                	push   $0x0
f0101651:	e8 0d f7 ff ff       	call   f0100d63 <page_alloc>
f0101656:	89 c3                	mov    %eax,%ebx
f0101658:	83 c4 10             	add    $0x10,%esp
f010165b:	85 c0                	test   %eax,%eax
f010165d:	75 19                	jne    f0101678 <mem_init+0x5d8>
f010165f:	68 96 46 10 f0       	push   $0xf0104696
f0101664:	68 d5 45 10 f0       	push   $0xf01045d5
f0101669:	68 4a 03 00 00       	push   $0x34a
f010166e:	68 af 45 10 f0       	push   $0xf01045af
f0101673:	e8 28 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101678:	83 ec 0c             	sub    $0xc,%esp
f010167b:	6a 00                	push   $0x0
f010167d:	e8 e1 f6 ff ff       	call   f0100d63 <page_alloc>
f0101682:	89 c6                	mov    %eax,%esi
f0101684:	83 c4 10             	add    $0x10,%esp
f0101687:	85 c0                	test   %eax,%eax
f0101689:	75 19                	jne    f01016a4 <mem_init+0x604>
f010168b:	68 ac 46 10 f0       	push   $0xf01046ac
f0101690:	68 d5 45 10 f0       	push   $0xf01045d5
f0101695:	68 4b 03 00 00       	push   $0x34b
f010169a:	68 af 45 10 f0       	push   $0xf01045af
f010169f:	e8 fc e9 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016a4:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01016a7:	75 19                	jne    f01016c2 <mem_init+0x622>
f01016a9:	68 c2 46 10 f0       	push   $0xf01046c2
f01016ae:	68 d5 45 10 f0       	push   $0xf01045d5
f01016b3:	68 4e 03 00 00       	push   $0x34e
f01016b8:	68 af 45 10 f0       	push   $0xf01045af
f01016bd:	e8 de e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016c2:	39 c3                	cmp    %eax,%ebx
f01016c4:	74 05                	je     f01016cb <mem_init+0x62b>
f01016c6:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01016c9:	75 19                	jne    f01016e4 <mem_init+0x644>
f01016cb:	68 fc 49 10 f0       	push   $0xf01049fc
f01016d0:	68 d5 45 10 f0       	push   $0xf01045d5
f01016d5:	68 4f 03 00 00       	push   $0x34f
f01016da:	68 af 45 10 f0       	push   $0xf01045af
f01016df:	e8 bc e9 ff ff       	call   f01000a0 <_panic>
	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016e4:	a1 3c 41 17 f0       	mov    0xf017413c,%eax
f01016e9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016ec:	c7 05 3c 41 17 f0 00 	movl   $0x0,0xf017413c
f01016f3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016f6:	83 ec 0c             	sub    $0xc,%esp
f01016f9:	6a 00                	push   $0x0
f01016fb:	e8 63 f6 ff ff       	call   f0100d63 <page_alloc>
f0101700:	83 c4 10             	add    $0x10,%esp
f0101703:	85 c0                	test   %eax,%eax
f0101705:	74 19                	je     f0101720 <mem_init+0x680>
f0101707:	68 2b 47 10 f0       	push   $0xf010472b
f010170c:	68 d5 45 10 f0       	push   $0xf01045d5
f0101711:	68 55 03 00 00       	push   $0x355
f0101716:	68 af 45 10 f0       	push   $0xf01045af
f010171b:	e8 80 e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101720:	83 ec 04             	sub    $0x4,%esp
f0101723:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101726:	50                   	push   %eax
f0101727:	6a 00                	push   $0x0
f0101729:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f010172f:	e8 0d f8 ff ff       	call   f0100f41 <page_lookup>
f0101734:	83 c4 10             	add    $0x10,%esp
f0101737:	85 c0                	test   %eax,%eax
f0101739:	74 19                	je     f0101754 <mem_init+0x6b4>
f010173b:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0101740:	68 d5 45 10 f0       	push   $0xf01045d5
f0101745:	68 58 03 00 00       	push   $0x358
f010174a:	68 af 45 10 f0       	push   $0xf01045af
f010174f:	e8 4c e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101754:	6a 02                	push   $0x2
f0101756:	6a 00                	push   $0x0
f0101758:	53                   	push   %ebx
f0101759:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f010175f:	e8 7d f8 ff ff       	call   f0100fe1 <page_insert>
f0101764:	83 c4 10             	add    $0x10,%esp
f0101767:	85 c0                	test   %eax,%eax
f0101769:	78 19                	js     f0101784 <mem_init+0x6e4>
f010176b:	68 74 4a 10 f0       	push   $0xf0104a74
f0101770:	68 d5 45 10 f0       	push   $0xf01045d5
f0101775:	68 5b 03 00 00       	push   $0x35b
f010177a:	68 af 45 10 f0       	push   $0xf01045af
f010177f:	e8 1c e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101784:	83 ec 0c             	sub    $0xc,%esp
f0101787:	ff 75 d4             	pushl  -0x2c(%ebp)
f010178a:	e8 45 f6 ff ff       	call   f0100dd4 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010178f:	6a 02                	push   $0x2
f0101791:	6a 00                	push   $0x0
f0101793:	53                   	push   %ebx
f0101794:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f010179a:	e8 42 f8 ff ff       	call   f0100fe1 <page_insert>
f010179f:	83 c4 20             	add    $0x20,%esp
f01017a2:	85 c0                	test   %eax,%eax
f01017a4:	74 19                	je     f01017bf <mem_init+0x71f>
f01017a6:	68 a4 4a 10 f0       	push   $0xf0104aa4
f01017ab:	68 d5 45 10 f0       	push   $0xf01045d5
f01017b0:	68 5f 03 00 00       	push   $0x35f
f01017b5:	68 af 45 10 f0       	push   $0xf01045af
f01017ba:	e8 e1 e8 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01017bf:	8b 3d 08 4e 17 f0    	mov    0xf0174e08,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017c5:	a1 0c 4e 17 f0       	mov    0xf0174e0c,%eax
f01017ca:	89 c1                	mov    %eax,%ecx
f01017cc:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01017cf:	8b 17                	mov    (%edi),%edx
f01017d1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017da:	29 c8                	sub    %ecx,%eax
f01017dc:	c1 f8 03             	sar    $0x3,%eax
f01017df:	c1 e0 0c             	shl    $0xc,%eax
f01017e2:	39 c2                	cmp    %eax,%edx
f01017e4:	74 19                	je     f01017ff <mem_init+0x75f>
f01017e6:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01017eb:	68 d5 45 10 f0       	push   $0xf01045d5
f01017f0:	68 60 03 00 00       	push   $0x360
f01017f5:	68 af 45 10 f0       	push   $0xf01045af
f01017fa:	e8 a1 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017ff:	ba 00 00 00 00       	mov    $0x0,%edx
f0101804:	89 f8                	mov    %edi,%eax
f0101806:	e8 56 f1 ff ff       	call   f0100961 <check_va2pa>
f010180b:	89 da                	mov    %ebx,%edx
f010180d:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101810:	c1 fa 03             	sar    $0x3,%edx
f0101813:	c1 e2 0c             	shl    $0xc,%edx
f0101816:	39 d0                	cmp    %edx,%eax
f0101818:	74 19                	je     f0101833 <mem_init+0x793>
f010181a:	68 fc 4a 10 f0       	push   $0xf0104afc
f010181f:	68 d5 45 10 f0       	push   $0xf01045d5
f0101824:	68 61 03 00 00       	push   $0x361
f0101829:	68 af 45 10 f0       	push   $0xf01045af
f010182e:	e8 6d e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101833:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101838:	74 19                	je     f0101853 <mem_init+0x7b3>
f010183a:	68 7d 47 10 f0       	push   $0xf010477d
f010183f:	68 d5 45 10 f0       	push   $0xf01045d5
f0101844:	68 62 03 00 00       	push   $0x362
f0101849:	68 af 45 10 f0       	push   $0xf01045af
f010184e:	e8 4d e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101853:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101856:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010185b:	74 19                	je     f0101876 <mem_init+0x7d6>
f010185d:	68 8e 47 10 f0       	push   $0xf010478e
f0101862:	68 d5 45 10 f0       	push   $0xf01045d5
f0101867:	68 63 03 00 00       	push   $0x363
f010186c:	68 af 45 10 f0       	push   $0xf01045af
f0101871:	e8 2a e8 ff ff       	call   f01000a0 <_panic>
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101876:	6a 02                	push   $0x2
f0101878:	68 00 10 00 00       	push   $0x1000
f010187d:	56                   	push   %esi
f010187e:	57                   	push   %edi
f010187f:	e8 5d f7 ff ff       	call   f0100fe1 <page_insert>
f0101884:	83 c4 10             	add    $0x10,%esp
f0101887:	85 c0                	test   %eax,%eax
f0101889:	74 19                	je     f01018a4 <mem_init+0x804>
f010188b:	68 2c 4b 10 f0       	push   $0xf0104b2c
f0101890:	68 d5 45 10 f0       	push   $0xf01045d5
f0101895:	68 65 03 00 00       	push   $0x365
f010189a:	68 af 45 10 f0       	push   $0xf01045af
f010189f:	e8 fc e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018a4:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018a9:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
f01018ae:	e8 ae f0 ff ff       	call   f0100961 <check_va2pa>
f01018b3:	89 f2                	mov    %esi,%edx
f01018b5:	2b 15 0c 4e 17 f0    	sub    0xf0174e0c,%edx
f01018bb:	c1 fa 03             	sar    $0x3,%edx
f01018be:	c1 e2 0c             	shl    $0xc,%edx
f01018c1:	39 d0                	cmp    %edx,%eax
f01018c3:	74 19                	je     f01018de <mem_init+0x83e>
f01018c5:	68 68 4b 10 f0       	push   $0xf0104b68
f01018ca:	68 d5 45 10 f0       	push   $0xf01045d5
f01018cf:	68 66 03 00 00       	push   $0x366
f01018d4:	68 af 45 10 f0       	push   $0xf01045af
f01018d9:	e8 c2 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01018de:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018e3:	74 19                	je     f01018fe <mem_init+0x85e>
f01018e5:	68 9f 47 10 f0       	push   $0xf010479f
f01018ea:	68 d5 45 10 f0       	push   $0xf01045d5
f01018ef:	68 67 03 00 00       	push   $0x367
f01018f4:	68 af 45 10 f0       	push   $0xf01045af
f01018f9:	e8 a2 e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018fe:	83 ec 0c             	sub    $0xc,%esp
f0101901:	6a 00                	push   $0x0
f0101903:	e8 5b f4 ff ff       	call   f0100d63 <page_alloc>
f0101908:	83 c4 10             	add    $0x10,%esp
f010190b:	85 c0                	test   %eax,%eax
f010190d:	74 19                	je     f0101928 <mem_init+0x888>
f010190f:	68 2b 47 10 f0       	push   $0xf010472b
f0101914:	68 d5 45 10 f0       	push   $0xf01045d5
f0101919:	68 6a 03 00 00       	push   $0x36a
f010191e:	68 af 45 10 f0       	push   $0xf01045af
f0101923:	e8 78 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101928:	6a 02                	push   $0x2
f010192a:	68 00 10 00 00       	push   $0x1000
f010192f:	56                   	push   %esi
f0101930:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0101936:	e8 a6 f6 ff ff       	call   f0100fe1 <page_insert>
f010193b:	83 c4 10             	add    $0x10,%esp
f010193e:	85 c0                	test   %eax,%eax
f0101940:	74 19                	je     f010195b <mem_init+0x8bb>
f0101942:	68 2c 4b 10 f0       	push   $0xf0104b2c
f0101947:	68 d5 45 10 f0       	push   $0xf01045d5
f010194c:	68 6d 03 00 00       	push   $0x36d
f0101951:	68 af 45 10 f0       	push   $0xf01045af
f0101956:	e8 45 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010195b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101960:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
f0101965:	e8 f7 ef ff ff       	call   f0100961 <check_va2pa>
f010196a:	89 f2                	mov    %esi,%edx
f010196c:	2b 15 0c 4e 17 f0    	sub    0xf0174e0c,%edx
f0101972:	c1 fa 03             	sar    $0x3,%edx
f0101975:	c1 e2 0c             	shl    $0xc,%edx
f0101978:	39 d0                	cmp    %edx,%eax
f010197a:	74 19                	je     f0101995 <mem_init+0x8f5>
f010197c:	68 68 4b 10 f0       	push   $0xf0104b68
f0101981:	68 d5 45 10 f0       	push   $0xf01045d5
f0101986:	68 6e 03 00 00       	push   $0x36e
f010198b:	68 af 45 10 f0       	push   $0xf01045af
f0101990:	e8 0b e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101995:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010199a:	74 19                	je     f01019b5 <mem_init+0x915>
f010199c:	68 9f 47 10 f0       	push   $0xf010479f
f01019a1:	68 d5 45 10 f0       	push   $0xf01045d5
f01019a6:	68 6f 03 00 00       	push   $0x36f
f01019ab:	68 af 45 10 f0       	push   $0xf01045af
f01019b0:	e8 eb e6 ff ff       	call   f01000a0 <_panic>
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01019b5:	83 ec 0c             	sub    $0xc,%esp
f01019b8:	6a 00                	push   $0x0
f01019ba:	e8 a4 f3 ff ff       	call   f0100d63 <page_alloc>
f01019bf:	83 c4 10             	add    $0x10,%esp
f01019c2:	85 c0                	test   %eax,%eax
f01019c4:	74 19                	je     f01019df <mem_init+0x93f>
f01019c6:	68 2b 47 10 f0       	push   $0xf010472b
f01019cb:	68 d5 45 10 f0       	push   $0xf01045d5
f01019d0:	68 72 03 00 00       	push   $0x372
f01019d5:	68 af 45 10 f0       	push   $0xf01045af
f01019da:	e8 c1 e6 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019df:	8b 15 08 4e 17 f0    	mov    0xf0174e08,%edx
f01019e5:	8b 02                	mov    (%edx),%eax
f01019e7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019ec:	89 c1                	mov    %eax,%ecx
f01019ee:	c1 e9 0c             	shr    $0xc,%ecx
f01019f1:	3b 0d 04 4e 17 f0    	cmp    0xf0174e04,%ecx
f01019f7:	72 15                	jb     f0101a0e <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019f9:	50                   	push   %eax
f01019fa:	68 94 48 10 f0       	push   $0xf0104894
f01019ff:	68 75 03 00 00       	push   $0x375
f0101a04:	68 af 45 10 f0       	push   $0xf01045af
f0101a09:	e8 92 e6 ff ff       	call   f01000a0 <_panic>
f0101a0e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a13:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a16:	83 ec 04             	sub    $0x4,%esp
f0101a19:	6a 00                	push   $0x0
f0101a1b:	68 00 10 00 00       	push   $0x1000
f0101a20:	52                   	push   %edx
f0101a21:	e8 ea f3 ff ff       	call   f0100e10 <pgdir_walk>
f0101a26:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a29:	8d 57 04             	lea    0x4(%edi),%edx
f0101a2c:	83 c4 10             	add    $0x10,%esp
f0101a2f:	39 d0                	cmp    %edx,%eax
f0101a31:	74 19                	je     f0101a4c <mem_init+0x9ac>
f0101a33:	68 98 4b 10 f0       	push   $0xf0104b98
f0101a38:	68 d5 45 10 f0       	push   $0xf01045d5
f0101a3d:	68 76 03 00 00       	push   $0x376
f0101a42:	68 af 45 10 f0       	push   $0xf01045af
f0101a47:	e8 54 e6 ff ff       	call   f01000a0 <_panic>
	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a4c:	6a 06                	push   $0x6
f0101a4e:	68 00 10 00 00       	push   $0x1000
f0101a53:	56                   	push   %esi
f0101a54:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0101a5a:	e8 82 f5 ff ff       	call   f0100fe1 <page_insert>
f0101a5f:	83 c4 10             	add    $0x10,%esp
f0101a62:	85 c0                	test   %eax,%eax
f0101a64:	74 19                	je     f0101a7f <mem_init+0x9df>
f0101a66:	68 d8 4b 10 f0       	push   $0xf0104bd8
f0101a6b:	68 d5 45 10 f0       	push   $0xf01045d5
f0101a70:	68 78 03 00 00       	push   $0x378
f0101a75:	68 af 45 10 f0       	push   $0xf01045af
f0101a7a:	e8 21 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a7f:	8b 3d 08 4e 17 f0    	mov    0xf0174e08,%edi
f0101a85:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a8a:	89 f8                	mov    %edi,%eax
f0101a8c:	e8 d0 ee ff ff       	call   f0100961 <check_va2pa>
f0101a91:	89 f2                	mov    %esi,%edx
f0101a93:	2b 15 0c 4e 17 f0    	sub    0xf0174e0c,%edx
f0101a99:	c1 fa 03             	sar    $0x3,%edx
f0101a9c:	c1 e2 0c             	shl    $0xc,%edx
f0101a9f:	39 d0                	cmp    %edx,%eax
f0101aa1:	74 19                	je     f0101abc <mem_init+0xa1c>
f0101aa3:	68 68 4b 10 f0       	push   $0xf0104b68
f0101aa8:	68 d5 45 10 f0       	push   $0xf01045d5
f0101aad:	68 79 03 00 00       	push   $0x379
f0101ab2:	68 af 45 10 f0       	push   $0xf01045af
f0101ab7:	e8 e4 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101abc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ac1:	74 19                	je     f0101adc <mem_init+0xa3c>
f0101ac3:	68 9f 47 10 f0       	push   $0xf010479f
f0101ac8:	68 d5 45 10 f0       	push   $0xf01045d5
f0101acd:	68 7a 03 00 00       	push   $0x37a
f0101ad2:	68 af 45 10 f0       	push   $0xf01045af
f0101ad7:	e8 c4 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101adc:	83 ec 04             	sub    $0x4,%esp
f0101adf:	6a 00                	push   $0x0
f0101ae1:	68 00 10 00 00       	push   $0x1000
f0101ae6:	57                   	push   %edi
f0101ae7:	e8 24 f3 ff ff       	call   f0100e10 <pgdir_walk>
f0101aec:	83 c4 10             	add    $0x10,%esp
f0101aef:	f6 00 04             	testb  $0x4,(%eax)
f0101af2:	75 19                	jne    f0101b0d <mem_init+0xa6d>
f0101af4:	68 18 4c 10 f0       	push   $0xf0104c18
f0101af9:	68 d5 45 10 f0       	push   $0xf01045d5
f0101afe:	68 7b 03 00 00       	push   $0x37b
f0101b03:	68 af 45 10 f0       	push   $0xf01045af
f0101b08:	e8 93 e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b0d:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
f0101b12:	f6 00 04             	testb  $0x4,(%eax)
f0101b15:	75 19                	jne    f0101b30 <mem_init+0xa90>
f0101b17:	68 b0 47 10 f0       	push   $0xf01047b0
f0101b1c:	68 d5 45 10 f0       	push   $0xf01045d5
f0101b21:	68 7c 03 00 00       	push   $0x37c
f0101b26:	68 af 45 10 f0       	push   $0xf01045af
f0101b2b:	e8 70 e5 ff ff       	call   f01000a0 <_panic>
	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b30:	6a 02                	push   $0x2
f0101b32:	68 00 10 00 00       	push   $0x1000
f0101b37:	56                   	push   %esi
f0101b38:	50                   	push   %eax
f0101b39:	e8 a3 f4 ff ff       	call   f0100fe1 <page_insert>
f0101b3e:	83 c4 10             	add    $0x10,%esp
f0101b41:	85 c0                	test   %eax,%eax
f0101b43:	74 19                	je     f0101b5e <mem_init+0xabe>
f0101b45:	68 2c 4b 10 f0       	push   $0xf0104b2c
f0101b4a:	68 d5 45 10 f0       	push   $0xf01045d5
f0101b4f:	68 7e 03 00 00       	push   $0x37e
f0101b54:	68 af 45 10 f0       	push   $0xf01045af
f0101b59:	e8 42 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b5e:	83 ec 04             	sub    $0x4,%esp
f0101b61:	6a 00                	push   $0x0
f0101b63:	68 00 10 00 00       	push   $0x1000
f0101b68:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0101b6e:	e8 9d f2 ff ff       	call   f0100e10 <pgdir_walk>
f0101b73:	83 c4 10             	add    $0x10,%esp
f0101b76:	f6 00 02             	testb  $0x2,(%eax)
f0101b79:	75 19                	jne    f0101b94 <mem_init+0xaf4>
f0101b7b:	68 4c 4c 10 f0       	push   $0xf0104c4c
f0101b80:	68 d5 45 10 f0       	push   $0xf01045d5
f0101b85:	68 7f 03 00 00       	push   $0x37f
f0101b8a:	68 af 45 10 f0       	push   $0xf01045af
f0101b8f:	e8 0c e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b94:	83 ec 04             	sub    $0x4,%esp
f0101b97:	6a 00                	push   $0x0
f0101b99:	68 00 10 00 00       	push   $0x1000
f0101b9e:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0101ba4:	e8 67 f2 ff ff       	call   f0100e10 <pgdir_walk>
f0101ba9:	83 c4 10             	add    $0x10,%esp
f0101bac:	f6 00 04             	testb  $0x4,(%eax)
f0101baf:	74 19                	je     f0101bca <mem_init+0xb2a>
f0101bb1:	68 80 4c 10 f0       	push   $0xf0104c80
f0101bb6:	68 d5 45 10 f0       	push   $0xf01045d5
f0101bbb:	68 80 03 00 00       	push   $0x380
f0101bc0:	68 af 45 10 f0       	push   $0xf01045af
f0101bc5:	e8 d6 e4 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101bca:	6a 02                	push   $0x2
f0101bcc:	68 00 00 40 00       	push   $0x400000
f0101bd1:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bd4:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0101bda:	e8 02 f4 ff ff       	call   f0100fe1 <page_insert>
f0101bdf:	83 c4 10             	add    $0x10,%esp
f0101be2:	85 c0                	test   %eax,%eax
f0101be4:	78 19                	js     f0101bff <mem_init+0xb5f>
f0101be6:	68 b8 4c 10 f0       	push   $0xf0104cb8
f0101beb:	68 d5 45 10 f0       	push   $0xf01045d5
f0101bf0:	68 83 03 00 00       	push   $0x383
f0101bf5:	68 af 45 10 f0       	push   $0xf01045af
f0101bfa:	e8 a1 e4 ff ff       	call   f01000a0 <_panic>
	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101bff:	6a 02                	push   $0x2
f0101c01:	68 00 10 00 00       	push   $0x1000
f0101c06:	53                   	push   %ebx
f0101c07:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0101c0d:	e8 cf f3 ff ff       	call   f0100fe1 <page_insert>
f0101c12:	83 c4 10             	add    $0x10,%esp
f0101c15:	85 c0                	test   %eax,%eax
f0101c17:	74 19                	je     f0101c32 <mem_init+0xb92>
f0101c19:	68 f0 4c 10 f0       	push   $0xf0104cf0
f0101c1e:	68 d5 45 10 f0       	push   $0xf01045d5
f0101c23:	68 85 03 00 00       	push   $0x385
f0101c28:	68 af 45 10 f0       	push   $0xf01045af
f0101c2d:	e8 6e e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c32:	83 ec 04             	sub    $0x4,%esp
f0101c35:	6a 00                	push   $0x0
f0101c37:	68 00 10 00 00       	push   $0x1000
f0101c3c:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0101c42:	e8 c9 f1 ff ff       	call   f0100e10 <pgdir_walk>
f0101c47:	83 c4 10             	add    $0x10,%esp
f0101c4a:	f6 00 04             	testb  $0x4,(%eax)
f0101c4d:	74 19                	je     f0101c68 <mem_init+0xbc8>
f0101c4f:	68 80 4c 10 f0       	push   $0xf0104c80
f0101c54:	68 d5 45 10 f0       	push   $0xf01045d5
f0101c59:	68 86 03 00 00       	push   $0x386
f0101c5e:	68 af 45 10 f0       	push   $0xf01045af
f0101c63:	e8 38 e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c68:	8b 3d 08 4e 17 f0    	mov    0xf0174e08,%edi
f0101c6e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c73:	89 f8                	mov    %edi,%eax
f0101c75:	e8 e7 ec ff ff       	call   f0100961 <check_va2pa>
f0101c7a:	89 c1                	mov    %eax,%ecx
f0101c7c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c7f:	89 d8                	mov    %ebx,%eax
f0101c81:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f0101c87:	c1 f8 03             	sar    $0x3,%eax
f0101c8a:	c1 e0 0c             	shl    $0xc,%eax
f0101c8d:	39 c1                	cmp    %eax,%ecx
f0101c8f:	74 19                	je     f0101caa <mem_init+0xc0a>
f0101c91:	68 2c 4d 10 f0       	push   $0xf0104d2c
f0101c96:	68 d5 45 10 f0       	push   $0xf01045d5
f0101c9b:	68 89 03 00 00       	push   $0x389
f0101ca0:	68 af 45 10 f0       	push   $0xf01045af
f0101ca5:	e8 f6 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101caa:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101caf:	89 f8                	mov    %edi,%eax
f0101cb1:	e8 ab ec ff ff       	call   f0100961 <check_va2pa>
f0101cb6:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101cb9:	74 19                	je     f0101cd4 <mem_init+0xc34>
f0101cbb:	68 58 4d 10 f0       	push   $0xf0104d58
f0101cc0:	68 d5 45 10 f0       	push   $0xf01045d5
f0101cc5:	68 8a 03 00 00       	push   $0x38a
f0101cca:	68 af 45 10 f0       	push   $0xf01045af
f0101ccf:	e8 cc e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cd4:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101cd9:	74 19                	je     f0101cf4 <mem_init+0xc54>
f0101cdb:	68 c6 47 10 f0       	push   $0xf01047c6
f0101ce0:	68 d5 45 10 f0       	push   $0xf01045d5
f0101ce5:	68 8c 03 00 00       	push   $0x38c
f0101cea:	68 af 45 10 f0       	push   $0xf01045af
f0101cef:	e8 ac e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101cf4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101cf9:	74 19                	je     f0101d14 <mem_init+0xc74>
f0101cfb:	68 d7 47 10 f0       	push   $0xf01047d7
f0101d00:	68 d5 45 10 f0       	push   $0xf01045d5
f0101d05:	68 8d 03 00 00       	push   $0x38d
f0101d0a:	68 af 45 10 f0       	push   $0xf01045af
f0101d0f:	e8 8c e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d14:	83 ec 0c             	sub    $0xc,%esp
f0101d17:	6a 00                	push   $0x0
f0101d19:	e8 45 f0 ff ff       	call   f0100d63 <page_alloc>
f0101d1e:	83 c4 10             	add    $0x10,%esp
f0101d21:	85 c0                	test   %eax,%eax
f0101d23:	74 04                	je     f0101d29 <mem_init+0xc89>
f0101d25:	39 c6                	cmp    %eax,%esi
f0101d27:	74 19                	je     f0101d42 <mem_init+0xca2>
f0101d29:	68 88 4d 10 f0       	push   $0xf0104d88
f0101d2e:	68 d5 45 10 f0       	push   $0xf01045d5
f0101d33:	68 90 03 00 00       	push   $0x390
f0101d38:	68 af 45 10 f0       	push   $0xf01045af
f0101d3d:	e8 5e e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d42:	83 ec 08             	sub    $0x8,%esp
f0101d45:	6a 00                	push   $0x0
f0101d47:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0101d4d:	e8 54 f2 ff ff       	call   f0100fa6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d52:	8b 3d 08 4e 17 f0    	mov    0xf0174e08,%edi
f0101d58:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d5d:	89 f8                	mov    %edi,%eax
f0101d5f:	e8 fd eb ff ff       	call   f0100961 <check_va2pa>
f0101d64:	83 c4 10             	add    $0x10,%esp
f0101d67:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d6a:	74 19                	je     f0101d85 <mem_init+0xce5>
f0101d6c:	68 ac 4d 10 f0       	push   $0xf0104dac
f0101d71:	68 d5 45 10 f0       	push   $0xf01045d5
f0101d76:	68 94 03 00 00       	push   $0x394
f0101d7b:	68 af 45 10 f0       	push   $0xf01045af
f0101d80:	e8 1b e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d85:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d8a:	89 f8                	mov    %edi,%eax
f0101d8c:	e8 d0 eb ff ff       	call   f0100961 <check_va2pa>
f0101d91:	89 da                	mov    %ebx,%edx
f0101d93:	2b 15 0c 4e 17 f0    	sub    0xf0174e0c,%edx
f0101d99:	c1 fa 03             	sar    $0x3,%edx
f0101d9c:	c1 e2 0c             	shl    $0xc,%edx
f0101d9f:	39 d0                	cmp    %edx,%eax
f0101da1:	74 19                	je     f0101dbc <mem_init+0xd1c>
f0101da3:	68 58 4d 10 f0       	push   $0xf0104d58
f0101da8:	68 d5 45 10 f0       	push   $0xf01045d5
f0101dad:	68 95 03 00 00       	push   $0x395
f0101db2:	68 af 45 10 f0       	push   $0xf01045af
f0101db7:	e8 e4 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101dbc:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101dc1:	74 19                	je     f0101ddc <mem_init+0xd3c>
f0101dc3:	68 7d 47 10 f0       	push   $0xf010477d
f0101dc8:	68 d5 45 10 f0       	push   $0xf01045d5
f0101dcd:	68 96 03 00 00       	push   $0x396
f0101dd2:	68 af 45 10 f0       	push   $0xf01045af
f0101dd7:	e8 c4 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ddc:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101de1:	74 19                	je     f0101dfc <mem_init+0xd5c>
f0101de3:	68 d7 47 10 f0       	push   $0xf01047d7
f0101de8:	68 d5 45 10 f0       	push   $0xf01045d5
f0101ded:	68 97 03 00 00       	push   $0x397
f0101df2:	68 af 45 10 f0       	push   $0xf01045af
f0101df7:	e8 a4 e2 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101dfc:	6a 00                	push   $0x0
f0101dfe:	68 00 10 00 00       	push   $0x1000
f0101e03:	53                   	push   %ebx
f0101e04:	57                   	push   %edi
f0101e05:	e8 d7 f1 ff ff       	call   f0100fe1 <page_insert>
f0101e0a:	83 c4 10             	add    $0x10,%esp
f0101e0d:	85 c0                	test   %eax,%eax
f0101e0f:	74 19                	je     f0101e2a <mem_init+0xd8a>
f0101e11:	68 d0 4d 10 f0       	push   $0xf0104dd0
f0101e16:	68 d5 45 10 f0       	push   $0xf01045d5
f0101e1b:	68 9a 03 00 00       	push   $0x39a
f0101e20:	68 af 45 10 f0       	push   $0xf01045af
f0101e25:	e8 76 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101e2a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e2f:	75 19                	jne    f0101e4a <mem_init+0xdaa>
f0101e31:	68 e8 47 10 f0       	push   $0xf01047e8
f0101e36:	68 d5 45 10 f0       	push   $0xf01045d5
f0101e3b:	68 9b 03 00 00       	push   $0x39b
f0101e40:	68 af 45 10 f0       	push   $0xf01045af
f0101e45:	e8 56 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101e4a:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e4d:	74 19                	je     f0101e68 <mem_init+0xdc8>
f0101e4f:	68 f4 47 10 f0       	push   $0xf01047f4
f0101e54:	68 d5 45 10 f0       	push   $0xf01045d5
f0101e59:	68 9c 03 00 00       	push   $0x39c
f0101e5e:	68 af 45 10 f0       	push   $0xf01045af
f0101e63:	e8 38 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e68:	83 ec 08             	sub    $0x8,%esp
f0101e6b:	68 00 10 00 00       	push   $0x1000
f0101e70:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0101e76:	e8 2b f1 ff ff       	call   f0100fa6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e7b:	8b 3d 08 4e 17 f0    	mov    0xf0174e08,%edi
f0101e81:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e86:	89 f8                	mov    %edi,%eax
f0101e88:	e8 d4 ea ff ff       	call   f0100961 <check_va2pa>
f0101e8d:	83 c4 10             	add    $0x10,%esp
f0101e90:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e93:	74 19                	je     f0101eae <mem_init+0xe0e>
f0101e95:	68 ac 4d 10 f0       	push   $0xf0104dac
f0101e9a:	68 d5 45 10 f0       	push   $0xf01045d5
f0101e9f:	68 a0 03 00 00       	push   $0x3a0
f0101ea4:	68 af 45 10 f0       	push   $0xf01045af
f0101ea9:	e8 f2 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101eae:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101eb3:	89 f8                	mov    %edi,%eax
f0101eb5:	e8 a7 ea ff ff       	call   f0100961 <check_va2pa>
f0101eba:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ebd:	74 19                	je     f0101ed8 <mem_init+0xe38>
f0101ebf:	68 08 4e 10 f0       	push   $0xf0104e08
f0101ec4:	68 d5 45 10 f0       	push   $0xf01045d5
f0101ec9:	68 a1 03 00 00       	push   $0x3a1
f0101ece:	68 af 45 10 f0       	push   $0xf01045af
f0101ed3:	e8 c8 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101ed8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101edd:	74 19                	je     f0101ef8 <mem_init+0xe58>
f0101edf:	68 09 48 10 f0       	push   $0xf0104809
f0101ee4:	68 d5 45 10 f0       	push   $0xf01045d5
f0101ee9:	68 a2 03 00 00       	push   $0x3a2
f0101eee:	68 af 45 10 f0       	push   $0xf01045af
f0101ef3:	e8 a8 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ef8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101efd:	74 19                	je     f0101f18 <mem_init+0xe78>
f0101eff:	68 d7 47 10 f0       	push   $0xf01047d7
f0101f04:	68 d5 45 10 f0       	push   $0xf01045d5
f0101f09:	68 a3 03 00 00       	push   $0x3a3
f0101f0e:	68 af 45 10 f0       	push   $0xf01045af
f0101f13:	e8 88 e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f18:	83 ec 0c             	sub    $0xc,%esp
f0101f1b:	6a 00                	push   $0x0
f0101f1d:	e8 41 ee ff ff       	call   f0100d63 <page_alloc>
f0101f22:	83 c4 10             	add    $0x10,%esp
f0101f25:	39 c3                	cmp    %eax,%ebx
f0101f27:	75 04                	jne    f0101f2d <mem_init+0xe8d>
f0101f29:	85 c0                	test   %eax,%eax
f0101f2b:	75 19                	jne    f0101f46 <mem_init+0xea6>
f0101f2d:	68 30 4e 10 f0       	push   $0xf0104e30
f0101f32:	68 d5 45 10 f0       	push   $0xf01045d5
f0101f37:	68 a6 03 00 00       	push   $0x3a6
f0101f3c:	68 af 45 10 f0       	push   $0xf01045af
f0101f41:	e8 5a e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f46:	83 ec 0c             	sub    $0xc,%esp
f0101f49:	6a 00                	push   $0x0
f0101f4b:	e8 13 ee ff ff       	call   f0100d63 <page_alloc>
f0101f50:	83 c4 10             	add    $0x10,%esp
f0101f53:	85 c0                	test   %eax,%eax
f0101f55:	74 19                	je     f0101f70 <mem_init+0xed0>
f0101f57:	68 2b 47 10 f0       	push   $0xf010472b
f0101f5c:	68 d5 45 10 f0       	push   $0xf01045d5
f0101f61:	68 a9 03 00 00       	push   $0x3a9
f0101f66:	68 af 45 10 f0       	push   $0xf01045af
f0101f6b:	e8 30 e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f70:	8b 0d 08 4e 17 f0    	mov    0xf0174e08,%ecx
f0101f76:	8b 11                	mov    (%ecx),%edx
f0101f78:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f7e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f81:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f0101f87:	c1 f8 03             	sar    $0x3,%eax
f0101f8a:	c1 e0 0c             	shl    $0xc,%eax
f0101f8d:	39 c2                	cmp    %eax,%edx
f0101f8f:	74 19                	je     f0101faa <mem_init+0xf0a>
f0101f91:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101f96:	68 d5 45 10 f0       	push   $0xf01045d5
f0101f9b:	68 ac 03 00 00       	push   $0x3ac
f0101fa0:	68 af 45 10 f0       	push   $0xf01045af
f0101fa5:	e8 f6 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101faa:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101fb0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fb3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fb8:	74 19                	je     f0101fd3 <mem_init+0xf33>
f0101fba:	68 8e 47 10 f0       	push   $0xf010478e
f0101fbf:	68 d5 45 10 f0       	push   $0xf01045d5
f0101fc4:	68 ae 03 00 00       	push   $0x3ae
f0101fc9:	68 af 45 10 f0       	push   $0xf01045af
f0101fce:	e8 cd e0 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101fd3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fd6:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fdc:	83 ec 0c             	sub    $0xc,%esp
f0101fdf:	50                   	push   %eax
f0101fe0:	e8 ef ed ff ff       	call   f0100dd4 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fe5:	83 c4 0c             	add    $0xc,%esp
f0101fe8:	6a 01                	push   $0x1
f0101fea:	68 00 10 40 00       	push   $0x401000
f0101fef:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0101ff5:	e8 16 ee ff ff       	call   f0100e10 <pgdir_walk>
f0101ffa:	89 c7                	mov    %eax,%edi
f0101ffc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fff:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
f0102004:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102007:	8b 40 04             	mov    0x4(%eax),%eax
f010200a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010200f:	8b 0d 04 4e 17 f0    	mov    0xf0174e04,%ecx
f0102015:	89 c2                	mov    %eax,%edx
f0102017:	c1 ea 0c             	shr    $0xc,%edx
f010201a:	83 c4 10             	add    $0x10,%esp
f010201d:	39 ca                	cmp    %ecx,%edx
f010201f:	72 15                	jb     f0102036 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102021:	50                   	push   %eax
f0102022:	68 94 48 10 f0       	push   $0xf0104894
f0102027:	68 b5 03 00 00       	push   $0x3b5
f010202c:	68 af 45 10 f0       	push   $0xf01045af
f0102031:	e8 6a e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102036:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010203b:	39 c7                	cmp    %eax,%edi
f010203d:	74 19                	je     f0102058 <mem_init+0xfb8>
f010203f:	68 1a 48 10 f0       	push   $0xf010481a
f0102044:	68 d5 45 10 f0       	push   $0xf01045d5
f0102049:	68 b6 03 00 00       	push   $0x3b6
f010204e:	68 af 45 10 f0       	push   $0xf01045af
f0102053:	e8 48 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102058:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010205b:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102062:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102065:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010206b:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f0102071:	c1 f8 03             	sar    $0x3,%eax
f0102074:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102077:	89 c2                	mov    %eax,%edx
f0102079:	c1 ea 0c             	shr    $0xc,%edx
f010207c:	39 d1                	cmp    %edx,%ecx
f010207e:	77 12                	ja     f0102092 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102080:	50                   	push   %eax
f0102081:	68 94 48 10 f0       	push   $0xf0104894
f0102086:	6a 56                	push   $0x56
f0102088:	68 bb 45 10 f0       	push   $0xf01045bb
f010208d:	e8 0e e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102092:	83 ec 04             	sub    $0x4,%esp
f0102095:	68 00 10 00 00       	push   $0x1000
f010209a:	68 ff 00 00 00       	push   $0xff
f010209f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020a4:	50                   	push   %eax
f01020a5:	e8 49 1b 00 00       	call   f0103bf3 <memset>
	page_free(pp0);
f01020aa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020ad:	89 3c 24             	mov    %edi,(%esp)
f01020b0:	e8 1f ed ff ff       	call   f0100dd4 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01020b5:	83 c4 0c             	add    $0xc,%esp
f01020b8:	6a 01                	push   $0x1
f01020ba:	6a 00                	push   $0x0
f01020bc:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f01020c2:	e8 49 ed ff ff       	call   f0100e10 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020c7:	89 fa                	mov    %edi,%edx
f01020c9:	2b 15 0c 4e 17 f0    	sub    0xf0174e0c,%edx
f01020cf:	c1 fa 03             	sar    $0x3,%edx
f01020d2:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020d5:	89 d0                	mov    %edx,%eax
f01020d7:	c1 e8 0c             	shr    $0xc,%eax
f01020da:	83 c4 10             	add    $0x10,%esp
f01020dd:	3b 05 04 4e 17 f0    	cmp    0xf0174e04,%eax
f01020e3:	72 12                	jb     f01020f7 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020e5:	52                   	push   %edx
f01020e6:	68 94 48 10 f0       	push   $0xf0104894
f01020eb:	6a 56                	push   $0x56
f01020ed:	68 bb 45 10 f0       	push   $0xf01045bb
f01020f2:	e8 a9 df ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f01020f7:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020fd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102100:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102106:	f6 00 01             	testb  $0x1,(%eax)
f0102109:	74 19                	je     f0102124 <mem_init+0x1084>
f010210b:	68 32 48 10 f0       	push   $0xf0104832
f0102110:	68 d5 45 10 f0       	push   $0xf01045d5
f0102115:	68 c0 03 00 00       	push   $0x3c0
f010211a:	68 af 45 10 f0       	push   $0xf01045af
f010211f:	e8 7c df ff ff       	call   f01000a0 <_panic>
f0102124:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102127:	39 c2                	cmp    %eax,%edx
f0102129:	75 db                	jne    f0102106 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010212b:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
f0102130:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102136:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102139:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010213f:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102142:	89 3d 3c 41 17 f0    	mov    %edi,0xf017413c

	// free the pages we took
	page_free(pp0);
f0102148:	83 ec 0c             	sub    $0xc,%esp
f010214b:	50                   	push   %eax
f010214c:	e8 83 ec ff ff       	call   f0100dd4 <page_free>
	page_free(pp1);
f0102151:	89 1c 24             	mov    %ebx,(%esp)
f0102154:	e8 7b ec ff ff       	call   f0100dd4 <page_free>
	page_free(pp2);
f0102159:	89 34 24             	mov    %esi,(%esp)
f010215c:	e8 73 ec ff ff       	call   f0100dd4 <page_free>

	cprintf("check_page() succeeded!\n");
f0102161:	c7 04 24 49 48 10 f0 	movl   $0xf0104849,(%esp)
f0102168:	e8 af 0b 00 00       	call   f0102d1c <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f010216d:	a1 0c 4e 17 f0       	mov    0xf0174e0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102172:	83 c4 10             	add    $0x10,%esp
f0102175:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010217a:	77 15                	ja     f0102191 <mem_init+0x10f1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010217c:	50                   	push   %eax
f010217d:	68 7c 49 10 f0       	push   $0xf010497c
f0102182:	68 c4 00 00 00       	push   $0xc4
f0102187:	68 af 45 10 f0       	push   $0xf01045af
f010218c:	e8 0f df ff ff       	call   f01000a0 <_panic>
f0102191:	83 ec 08             	sub    $0x8,%esp
f0102194:	6a 04                	push   $0x4
f0102196:	05 00 00 00 10       	add    $0x10000000,%eax
f010219b:	50                   	push   %eax
f010219c:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01021a1:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01021a6:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
f01021ab:	e8 37 ed ff ff       	call   f0100ee7 <boot_map_region>
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.

	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f01021b0:	a1 48 41 17 f0       	mov    0xf0174148,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021b5:	83 c4 10             	add    $0x10,%esp
f01021b8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021bd:	77 15                	ja     f01021d4 <mem_init+0x1134>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021bf:	50                   	push   %eax
f01021c0:	68 7c 49 10 f0       	push   $0xf010497c
f01021c5:	68 cd 00 00 00       	push   $0xcd
f01021ca:	68 af 45 10 f0       	push   $0xf01045af
f01021cf:	e8 cc de ff ff       	call   f01000a0 <_panic>
f01021d4:	83 ec 08             	sub    $0x8,%esp
f01021d7:	6a 04                	push   $0x4
f01021d9:	05 00 00 00 10       	add    $0x10000000,%eax
f01021de:	50                   	push   %eax
f01021df:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01021e4:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021e9:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
f01021ee:	e8 f4 ec ff ff       	call   f0100ee7 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021f3:	83 c4 10             	add    $0x10,%esp
f01021f6:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f01021fb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102200:	77 15                	ja     f0102217 <mem_init+0x1177>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102202:	50                   	push   %eax
f0102203:	68 7c 49 10 f0       	push   $0xf010497c
f0102208:	68 da 00 00 00       	push   $0xda
f010220d:	68 af 45 10 f0       	push   $0xf01045af
f0102212:	e8 89 de ff ff       	call   f01000a0 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102217:	83 ec 08             	sub    $0x8,%esp
f010221a:	6a 02                	push   $0x2
f010221c:	68 00 00 11 00       	push   $0x110000
f0102221:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102226:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010222b:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
f0102230:	e8 b2 ec ff ff       	call   f0100ee7 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f0102235:	83 c4 08             	add    $0x8,%esp
f0102238:	6a 02                	push   $0x2
f010223a:	6a 00                	push   $0x0
f010223c:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102241:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102246:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
f010224b:	e8 97 ec ff ff       	call   f0100ee7 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102250:	8b 1d 08 4e 17 f0    	mov    0xf0174e08,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102256:	a1 04 4e 17 f0       	mov    0xf0174e04,%eax
f010225b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010225e:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102265:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010226a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010226d:	8b 3d 0c 4e 17 f0    	mov    0xf0174e0c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102273:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102276:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102279:	be 00 00 00 00       	mov    $0x0,%esi
f010227e:	eb 55                	jmp    f01022d5 <mem_init+0x1235>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102280:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102286:	89 d8                	mov    %ebx,%eax
f0102288:	e8 d4 e6 ff ff       	call   f0100961 <check_va2pa>
f010228d:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102294:	77 15                	ja     f01022ab <mem_init+0x120b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102296:	57                   	push   %edi
f0102297:	68 7c 49 10 f0       	push   $0xf010497c
f010229c:	68 03 03 00 00       	push   $0x303
f01022a1:	68 af 45 10 f0       	push   $0xf01045af
f01022a6:	e8 f5 dd ff ff       	call   f01000a0 <_panic>
f01022ab:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01022b2:	39 d0                	cmp    %edx,%eax
f01022b4:	74 19                	je     f01022cf <mem_init+0x122f>
f01022b6:	68 54 4e 10 f0       	push   $0xf0104e54
f01022bb:	68 d5 45 10 f0       	push   $0xf01045d5
f01022c0:	68 03 03 00 00       	push   $0x303
f01022c5:	68 af 45 10 f0       	push   $0xf01045af
f01022ca:	e8 d1 dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022cf:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022d5:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01022d8:	77 a6                	ja     f0102280 <mem_init+0x11e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01022da:	8b 3d 48 41 17 f0    	mov    0xf0174148,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022e0:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01022e3:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01022e8:	89 f2                	mov    %esi,%edx
f01022ea:	89 d8                	mov    %ebx,%eax
f01022ec:	e8 70 e6 ff ff       	call   f0100961 <check_va2pa>
f01022f1:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01022f8:	77 15                	ja     f010230f <mem_init+0x126f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022fa:	57                   	push   %edi
f01022fb:	68 7c 49 10 f0       	push   $0xf010497c
f0102300:	68 08 03 00 00       	push   $0x308
f0102305:	68 af 45 10 f0       	push   $0xf01045af
f010230a:	e8 91 dd ff ff       	call   f01000a0 <_panic>
f010230f:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102316:	39 c2                	cmp    %eax,%edx
f0102318:	74 19                	je     f0102333 <mem_init+0x1293>
f010231a:	68 88 4e 10 f0       	push   $0xf0104e88
f010231f:	68 d5 45 10 f0       	push   $0xf01045d5
f0102324:	68 08 03 00 00       	push   $0x308
f0102329:	68 af 45 10 f0       	push   $0xf01045af
f010232e:	e8 6d dd ff ff       	call   f01000a0 <_panic>
f0102333:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102339:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f010233f:	75 a7                	jne    f01022e8 <mem_init+0x1248>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102341:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102344:	c1 e7 0c             	shl    $0xc,%edi
f0102347:	be 00 00 00 00       	mov    $0x0,%esi
f010234c:	eb 30                	jmp    f010237e <mem_init+0x12de>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010234e:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102354:	89 d8                	mov    %ebx,%eax
f0102356:	e8 06 e6 ff ff       	call   f0100961 <check_va2pa>
f010235b:	39 c6                	cmp    %eax,%esi
f010235d:	74 19                	je     f0102378 <mem_init+0x12d8>
f010235f:	68 bc 4e 10 f0       	push   $0xf0104ebc
f0102364:	68 d5 45 10 f0       	push   $0xf01045d5
f0102369:	68 0c 03 00 00       	push   $0x30c
f010236e:	68 af 45 10 f0       	push   $0xf01045af
f0102373:	e8 28 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102378:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010237e:	39 fe                	cmp    %edi,%esi
f0102380:	72 cc                	jb     f010234e <mem_init+0x12ae>
f0102382:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102387:	89 f2                	mov    %esi,%edx
f0102389:	89 d8                	mov    %ebx,%eax
f010238b:	e8 d1 e5 ff ff       	call   f0100961 <check_va2pa>
f0102390:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f0102396:	39 c2                	cmp    %eax,%edx
f0102398:	74 19                	je     f01023b3 <mem_init+0x1313>
f010239a:	68 e4 4e 10 f0       	push   $0xf0104ee4
f010239f:	68 d5 45 10 f0       	push   $0xf01045d5
f01023a4:	68 10 03 00 00       	push   $0x310
f01023a9:	68 af 45 10 f0       	push   $0xf01045af
f01023ae:	e8 ed dc ff ff       	call   f01000a0 <_panic>
f01023b3:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01023b9:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01023bf:	75 c6                	jne    f0102387 <mem_init+0x12e7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023c1:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01023c6:	89 d8                	mov    %ebx,%eax
f01023c8:	e8 94 e5 ff ff       	call   f0100961 <check_va2pa>
f01023cd:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023d0:	74 51                	je     f0102423 <mem_init+0x1383>
f01023d2:	68 2c 4f 10 f0       	push   $0xf0104f2c
f01023d7:	68 d5 45 10 f0       	push   $0xf01045d5
f01023dc:	68 11 03 00 00       	push   $0x311
f01023e1:	68 af 45 10 f0       	push   $0xf01045af
f01023e6:	e8 b5 dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01023eb:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01023f0:	72 36                	jb     f0102428 <mem_init+0x1388>
f01023f2:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01023f7:	76 07                	jbe    f0102400 <mem_init+0x1360>
f01023f9:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023fe:	75 28                	jne    f0102428 <mem_init+0x1388>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102400:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102404:	0f 85 83 00 00 00    	jne    f010248d <mem_init+0x13ed>
f010240a:	68 62 48 10 f0       	push   $0xf0104862
f010240f:	68 d5 45 10 f0       	push   $0xf01045d5
f0102414:	68 1a 03 00 00       	push   $0x31a
f0102419:	68 af 45 10 f0       	push   $0xf01045af
f010241e:	e8 7d dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102423:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102428:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010242d:	76 3f                	jbe    f010246e <mem_init+0x13ce>
				assert(pgdir[i] & PTE_P);
f010242f:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102432:	f6 c2 01             	test   $0x1,%dl
f0102435:	75 19                	jne    f0102450 <mem_init+0x13b0>
f0102437:	68 62 48 10 f0       	push   $0xf0104862
f010243c:	68 d5 45 10 f0       	push   $0xf01045d5
f0102441:	68 1e 03 00 00       	push   $0x31e
f0102446:	68 af 45 10 f0       	push   $0xf01045af
f010244b:	e8 50 dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f0102450:	f6 c2 02             	test   $0x2,%dl
f0102453:	75 38                	jne    f010248d <mem_init+0x13ed>
f0102455:	68 73 48 10 f0       	push   $0xf0104873
f010245a:	68 d5 45 10 f0       	push   $0xf01045d5
f010245f:	68 1f 03 00 00       	push   $0x31f
f0102464:	68 af 45 10 f0       	push   $0xf01045af
f0102469:	e8 32 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f010246e:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102472:	74 19                	je     f010248d <mem_init+0x13ed>
f0102474:	68 84 48 10 f0       	push   $0xf0104884
f0102479:	68 d5 45 10 f0       	push   $0xf01045d5
f010247e:	68 21 03 00 00       	push   $0x321
f0102483:	68 af 45 10 f0       	push   $0xf01045af
f0102488:	e8 13 dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010248d:	83 c0 01             	add    $0x1,%eax
f0102490:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102495:	0f 86 50 ff ff ff    	jbe    f01023eb <mem_init+0x134b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010249b:	83 ec 0c             	sub    $0xc,%esp
f010249e:	68 5c 4f 10 f0       	push   $0xf0104f5c
f01024a3:	e8 74 08 00 00       	call   f0102d1c <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024a8:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024ad:	83 c4 10             	add    $0x10,%esp
f01024b0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024b5:	77 15                	ja     f01024cc <mem_init+0x142c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024b7:	50                   	push   %eax
f01024b8:	68 7c 49 10 f0       	push   $0xf010497c
f01024bd:	68 f1 00 00 00       	push   $0xf1
f01024c2:	68 af 45 10 f0       	push   $0xf01045af
f01024c7:	e8 d4 db ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01024cc:	05 00 00 00 10       	add    $0x10000000,%eax
f01024d1:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01024d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01024d9:	e8 e7 e4 ff ff       	call   f01009c5 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01024de:	0f 20 c0             	mov    %cr0,%eax
f01024e1:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01024e4:	0d 23 00 05 80       	or     $0x80050023,%eax
f01024e9:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01024ec:	83 ec 0c             	sub    $0xc,%esp
f01024ef:	6a 00                	push   $0x0
f01024f1:	e8 6d e8 ff ff       	call   f0100d63 <page_alloc>
f01024f6:	89 c3                	mov    %eax,%ebx
f01024f8:	83 c4 10             	add    $0x10,%esp
f01024fb:	85 c0                	test   %eax,%eax
f01024fd:	75 19                	jne    f0102518 <mem_init+0x1478>
f01024ff:	68 80 46 10 f0       	push   $0xf0104680
f0102504:	68 d5 45 10 f0       	push   $0xf01045d5
f0102509:	68 db 03 00 00       	push   $0x3db
f010250e:	68 af 45 10 f0       	push   $0xf01045af
f0102513:	e8 88 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102518:	83 ec 0c             	sub    $0xc,%esp
f010251b:	6a 00                	push   $0x0
f010251d:	e8 41 e8 ff ff       	call   f0100d63 <page_alloc>
f0102522:	89 c7                	mov    %eax,%edi
f0102524:	83 c4 10             	add    $0x10,%esp
f0102527:	85 c0                	test   %eax,%eax
f0102529:	75 19                	jne    f0102544 <mem_init+0x14a4>
f010252b:	68 96 46 10 f0       	push   $0xf0104696
f0102530:	68 d5 45 10 f0       	push   $0xf01045d5
f0102535:	68 dc 03 00 00       	push   $0x3dc
f010253a:	68 af 45 10 f0       	push   $0xf01045af
f010253f:	e8 5c db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0102544:	83 ec 0c             	sub    $0xc,%esp
f0102547:	6a 00                	push   $0x0
f0102549:	e8 15 e8 ff ff       	call   f0100d63 <page_alloc>
f010254e:	89 c6                	mov    %eax,%esi
f0102550:	83 c4 10             	add    $0x10,%esp
f0102553:	85 c0                	test   %eax,%eax
f0102555:	75 19                	jne    f0102570 <mem_init+0x14d0>
f0102557:	68 ac 46 10 f0       	push   $0xf01046ac
f010255c:	68 d5 45 10 f0       	push   $0xf01045d5
f0102561:	68 dd 03 00 00       	push   $0x3dd
f0102566:	68 af 45 10 f0       	push   $0xf01045af
f010256b:	e8 30 db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f0102570:	83 ec 0c             	sub    $0xc,%esp
f0102573:	53                   	push   %ebx
f0102574:	e8 5b e8 ff ff       	call   f0100dd4 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102579:	89 f8                	mov    %edi,%eax
f010257b:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f0102581:	c1 f8 03             	sar    $0x3,%eax
f0102584:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102587:	89 c2                	mov    %eax,%edx
f0102589:	c1 ea 0c             	shr    $0xc,%edx
f010258c:	83 c4 10             	add    $0x10,%esp
f010258f:	3b 15 04 4e 17 f0    	cmp    0xf0174e04,%edx
f0102595:	72 12                	jb     f01025a9 <mem_init+0x1509>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102597:	50                   	push   %eax
f0102598:	68 94 48 10 f0       	push   $0xf0104894
f010259d:	6a 56                	push   $0x56
f010259f:	68 bb 45 10 f0       	push   $0xf01045bb
f01025a4:	e8 f7 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01025a9:	83 ec 04             	sub    $0x4,%esp
f01025ac:	68 00 10 00 00       	push   $0x1000
f01025b1:	6a 01                	push   $0x1
f01025b3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025b8:	50                   	push   %eax
f01025b9:	e8 35 16 00 00       	call   f0103bf3 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025be:	89 f0                	mov    %esi,%eax
f01025c0:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f01025c6:	c1 f8 03             	sar    $0x3,%eax
f01025c9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025cc:	89 c2                	mov    %eax,%edx
f01025ce:	c1 ea 0c             	shr    $0xc,%edx
f01025d1:	83 c4 10             	add    $0x10,%esp
f01025d4:	3b 15 04 4e 17 f0    	cmp    0xf0174e04,%edx
f01025da:	72 12                	jb     f01025ee <mem_init+0x154e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025dc:	50                   	push   %eax
f01025dd:	68 94 48 10 f0       	push   $0xf0104894
f01025e2:	6a 56                	push   $0x56
f01025e4:	68 bb 45 10 f0       	push   $0xf01045bb
f01025e9:	e8 b2 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01025ee:	83 ec 04             	sub    $0x4,%esp
f01025f1:	68 00 10 00 00       	push   $0x1000
f01025f6:	6a 02                	push   $0x2
f01025f8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025fd:	50                   	push   %eax
f01025fe:	e8 f0 15 00 00       	call   f0103bf3 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102603:	6a 02                	push   $0x2
f0102605:	68 00 10 00 00       	push   $0x1000
f010260a:	57                   	push   %edi
f010260b:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0102611:	e8 cb e9 ff ff       	call   f0100fe1 <page_insert>
	assert(pp1->pp_ref == 1);
f0102616:	83 c4 20             	add    $0x20,%esp
f0102619:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010261e:	74 19                	je     f0102639 <mem_init+0x1599>
f0102620:	68 7d 47 10 f0       	push   $0xf010477d
f0102625:	68 d5 45 10 f0       	push   $0xf01045d5
f010262a:	68 e2 03 00 00       	push   $0x3e2
f010262f:	68 af 45 10 f0       	push   $0xf01045af
f0102634:	e8 67 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102639:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102640:	01 01 01 
f0102643:	74 19                	je     f010265e <mem_init+0x15be>
f0102645:	68 7c 4f 10 f0       	push   $0xf0104f7c
f010264a:	68 d5 45 10 f0       	push   $0xf01045d5
f010264f:	68 e3 03 00 00       	push   $0x3e3
f0102654:	68 af 45 10 f0       	push   $0xf01045af
f0102659:	e8 42 da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010265e:	6a 02                	push   $0x2
f0102660:	68 00 10 00 00       	push   $0x1000
f0102665:	56                   	push   %esi
f0102666:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f010266c:	e8 70 e9 ff ff       	call   f0100fe1 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102671:	83 c4 10             	add    $0x10,%esp
f0102674:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010267b:	02 02 02 
f010267e:	74 19                	je     f0102699 <mem_init+0x15f9>
f0102680:	68 a0 4f 10 f0       	push   $0xf0104fa0
f0102685:	68 d5 45 10 f0       	push   $0xf01045d5
f010268a:	68 e5 03 00 00       	push   $0x3e5
f010268f:	68 af 45 10 f0       	push   $0xf01045af
f0102694:	e8 07 da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0102699:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010269e:	74 19                	je     f01026b9 <mem_init+0x1619>
f01026a0:	68 9f 47 10 f0       	push   $0xf010479f
f01026a5:	68 d5 45 10 f0       	push   $0xf01045d5
f01026aa:	68 e6 03 00 00       	push   $0x3e6
f01026af:	68 af 45 10 f0       	push   $0xf01045af
f01026b4:	e8 e7 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01026b9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01026be:	74 19                	je     f01026d9 <mem_init+0x1639>
f01026c0:	68 09 48 10 f0       	push   $0xf0104809
f01026c5:	68 d5 45 10 f0       	push   $0xf01045d5
f01026ca:	68 e7 03 00 00       	push   $0x3e7
f01026cf:	68 af 45 10 f0       	push   $0xf01045af
f01026d4:	e8 c7 d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01026d9:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01026e0:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026e3:	89 f0                	mov    %esi,%eax
f01026e5:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f01026eb:	c1 f8 03             	sar    $0x3,%eax
f01026ee:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026f1:	89 c2                	mov    %eax,%edx
f01026f3:	c1 ea 0c             	shr    $0xc,%edx
f01026f6:	3b 15 04 4e 17 f0    	cmp    0xf0174e04,%edx
f01026fc:	72 12                	jb     f0102710 <mem_init+0x1670>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026fe:	50                   	push   %eax
f01026ff:	68 94 48 10 f0       	push   $0xf0104894
f0102704:	6a 56                	push   $0x56
f0102706:	68 bb 45 10 f0       	push   $0xf01045bb
f010270b:	e8 90 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102710:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102717:	03 03 03 
f010271a:	74 19                	je     f0102735 <mem_init+0x1695>
f010271c:	68 c4 4f 10 f0       	push   $0xf0104fc4
f0102721:	68 d5 45 10 f0       	push   $0xf01045d5
f0102726:	68 e9 03 00 00       	push   $0x3e9
f010272b:	68 af 45 10 f0       	push   $0xf01045af
f0102730:	e8 6b d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102735:	83 ec 08             	sub    $0x8,%esp
f0102738:	68 00 10 00 00       	push   $0x1000
f010273d:	ff 35 08 4e 17 f0    	pushl  0xf0174e08
f0102743:	e8 5e e8 ff ff       	call   f0100fa6 <page_remove>
	assert(pp2->pp_ref == 0);
f0102748:	83 c4 10             	add    $0x10,%esp
f010274b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102750:	74 19                	je     f010276b <mem_init+0x16cb>
f0102752:	68 d7 47 10 f0       	push   $0xf01047d7
f0102757:	68 d5 45 10 f0       	push   $0xf01045d5
f010275c:	68 eb 03 00 00       	push   $0x3eb
f0102761:	68 af 45 10 f0       	push   $0xf01045af
f0102766:	e8 35 d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010276b:	8b 0d 08 4e 17 f0    	mov    0xf0174e08,%ecx
f0102771:	8b 11                	mov    (%ecx),%edx
f0102773:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102779:	89 d8                	mov    %ebx,%eax
f010277b:	2b 05 0c 4e 17 f0    	sub    0xf0174e0c,%eax
f0102781:	c1 f8 03             	sar    $0x3,%eax
f0102784:	c1 e0 0c             	shl    $0xc,%eax
f0102787:	39 c2                	cmp    %eax,%edx
f0102789:	74 19                	je     f01027a4 <mem_init+0x1704>
f010278b:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102790:	68 d5 45 10 f0       	push   $0xf01045d5
f0102795:	68 ee 03 00 00       	push   $0x3ee
f010279a:	68 af 45 10 f0       	push   $0xf01045af
f010279f:	e8 fc d8 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01027a4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01027aa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01027af:	74 19                	je     f01027ca <mem_init+0x172a>
f01027b1:	68 8e 47 10 f0       	push   $0xf010478e
f01027b6:	68 d5 45 10 f0       	push   $0xf01045d5
f01027bb:	68 f0 03 00 00       	push   $0x3f0
f01027c0:	68 af 45 10 f0       	push   $0xf01045af
f01027c5:	e8 d6 d8 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01027ca:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01027d0:	83 ec 0c             	sub    $0xc,%esp
f01027d3:	53                   	push   %ebx
f01027d4:	e8 fb e5 ff ff       	call   f0100dd4 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01027d9:	c7 04 24 f0 4f 10 f0 	movl   $0xf0104ff0,(%esp)
f01027e0:	e8 37 05 00 00       	call   f0102d1c <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01027e5:	83 c4 10             	add    $0x10,%esp
f01027e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027eb:	5b                   	pop    %ebx
f01027ec:	5e                   	pop    %esi
f01027ed:	5f                   	pop    %edi
f01027ee:	5d                   	pop    %ebp
f01027ef:	c3                   	ret    

f01027f0 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01027f0:	55                   	push   %ebp
f01027f1:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01027f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027f6:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01027f9:	5d                   	pop    %ebp
f01027fa:	c3                   	ret    

f01027fb <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01027fb:	55                   	push   %ebp
f01027fc:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f01027fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0102803:	5d                   	pop    %ebp
f0102804:	c3                   	ret    

f0102805 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102805:	55                   	push   %ebp
f0102806:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f0102808:	5d                   	pop    %ebp
f0102809:	c3                   	ret    

f010280a <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010280a:	55                   	push   %ebp
f010280b:	89 e5                	mov    %esp,%ebp
f010280d:	8b 55 08             	mov    0x8(%ebp),%edx
f0102810:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102813:	85 d2                	test   %edx,%edx
f0102815:	75 11                	jne    f0102828 <envid2env+0x1e>
		*env_store = curenv;
f0102817:	a1 44 41 17 f0       	mov    0xf0174144,%eax
f010281c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010281f:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102821:	b8 00 00 00 00       	mov    $0x0,%eax
f0102826:	eb 5e                	jmp    f0102886 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102828:	89 d0                	mov    %edx,%eax
f010282a:	25 ff 03 00 00       	and    $0x3ff,%eax
f010282f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102832:	c1 e0 05             	shl    $0x5,%eax
f0102835:	03 05 48 41 17 f0    	add    0xf0174148,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010283b:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f010283f:	74 05                	je     f0102846 <envid2env+0x3c>
f0102841:	3b 50 48             	cmp    0x48(%eax),%edx
f0102844:	74 10                	je     f0102856 <envid2env+0x4c>
		*env_store = 0;
f0102846:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102849:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010284f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102854:	eb 30                	jmp    f0102886 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102856:	84 c9                	test   %cl,%cl
f0102858:	74 22                	je     f010287c <envid2env+0x72>
f010285a:	8b 15 44 41 17 f0    	mov    0xf0174144,%edx
f0102860:	39 d0                	cmp    %edx,%eax
f0102862:	74 18                	je     f010287c <envid2env+0x72>
f0102864:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102867:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f010286a:	74 10                	je     f010287c <envid2env+0x72>
		*env_store = 0;
f010286c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010286f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102875:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010287a:	eb 0a                	jmp    f0102886 <envid2env+0x7c>
	}

	*env_store = e;
f010287c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010287f:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102881:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102886:	5d                   	pop    %ebp
f0102887:	c3                   	ret    

f0102888 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102888:	55                   	push   %ebp
f0102889:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f010288b:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f0102890:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102893:	b8 23 00 00 00       	mov    $0x23,%eax
f0102898:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f010289a:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f010289c:	b8 10 00 00 00       	mov    $0x10,%eax
f01028a1:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01028a3:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01028a5:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01028a7:	ea ae 28 10 f0 08 00 	ljmp   $0x8,$0xf01028ae
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01028ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01028b3:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01028b6:	5d                   	pop    %ebp
f01028b7:	c3                   	ret    

f01028b8 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01028b8:	55                   	push   %ebp
f01028b9:	89 e5                	mov    %esp,%ebp
f01028bb:	56                   	push   %esi
f01028bc:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1; i>=0; i--) {
		envs[i].env_id = 0;
f01028bd:	8b 35 48 41 17 f0    	mov    0xf0174148,%esi
f01028c3:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01028c9:	8d 5e a0             	lea    -0x60(%esi),%ebx
f01028cc:	ba 00 00 00 00       	mov    $0x0,%edx
f01028d1:	89 c1                	mov    %eax,%ecx
f01028d3:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f01028da:	89 50 44             	mov    %edx,0x44(%eax)
f01028dd:	83 e8 60             	sub    $0x60,%eax
		env_free_list = envs+i;
f01028e0:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1; i>=0; i--) {
f01028e2:	39 d8                	cmp    %ebx,%eax
f01028e4:	75 eb                	jne    f01028d1 <env_init+0x19>
f01028e6:	89 35 4c 41 17 f0    	mov    %esi,0xf017414c
		envs[i].env_link = env_free_list;
		env_free_list = envs+i;
	}
		
	// Per-CPU part of the initialization
	env_init_percpu();
f01028ec:	e8 97 ff ff ff       	call   f0102888 <env_init_percpu>
}
f01028f1:	5b                   	pop    %ebx
f01028f2:	5e                   	pop    %esi
f01028f3:	5d                   	pop    %ebp
f01028f4:	c3                   	ret    

f01028f5 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01028f5:	55                   	push   %ebp
f01028f6:	89 e5                	mov    %esp,%ebp
f01028f8:	56                   	push   %esi
f01028f9:	53                   	push   %ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01028fa:	8b 1d 4c 41 17 f0    	mov    0xf017414c,%ebx
f0102900:	85 db                	test   %ebx,%ebx
f0102902:	0f 84 6f 01 00 00    	je     f0102a77 <env_alloc+0x182>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102908:	83 ec 0c             	sub    $0xc,%esp
f010290b:	6a 01                	push   $0x1
f010290d:	e8 51 e4 ff ff       	call   f0100d63 <page_alloc>
f0102912:	83 c4 10             	add    $0x10,%esp
f0102915:	85 c0                	test   %eax,%eax
f0102917:	0f 84 61 01 00 00    	je     f0102a7e <env_alloc+0x189>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010291d:	89 c2                	mov    %eax,%edx
f010291f:	2b 15 0c 4e 17 f0    	sub    0xf0174e0c,%edx
f0102925:	c1 fa 03             	sar    $0x3,%edx
f0102928:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010292b:	89 d1                	mov    %edx,%ecx
f010292d:	c1 e9 0c             	shr    $0xc,%ecx
f0102930:	3b 0d 04 4e 17 f0    	cmp    0xf0174e04,%ecx
f0102936:	72 12                	jb     f010294a <env_alloc+0x55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102938:	52                   	push   %edx
f0102939:	68 94 48 10 f0       	push   $0xf0104894
f010293e:	6a 56                	push   $0x56
f0102940:	68 bb 45 10 f0       	push   $0xf01045bb
f0102945:	e8 56 d7 ff ff       	call   f01000a0 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
f010294a:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102950:	89 53 5c             	mov    %edx,0x5c(%ebx)
	p->pp_ref = 0;
f0102953:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	p->pp_link = NULL;
f0102959:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f010295f:	ba 00 00 00 00       	mov    $0x0,%edx
	for(i=0; i<PDX(UTOP); i++)
		e->env_pgdir[i] = 0;
f0102964:	8b 4b 5c             	mov    0x5c(%ebx),%ecx
f0102967:	c7 04 11 00 00 00 00 	movl   $0x0,(%ecx,%edx,1)
f010296e:	83 c2 04             	add    $0x4,%edx

	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
	p->pp_ref = 0;
	p->pp_link = NULL;
	for(i=0; i<PDX(UTOP); i++)
f0102971:	81 fa ec 0e 00 00    	cmp    $0xeec,%edx
f0102977:	75 eb                	jne    f0102964 <env_alloc+0x6f>
		e->env_pgdir[i] = 0;
	for(; i<NPDENTRIES; i++)
		e->env_pgdir[i] = kern_pgdir[i];
f0102979:	8b 0d 08 4e 17 f0    	mov    0xf0174e08,%ecx
f010297f:	8b 34 11             	mov    (%ecx,%edx,1),%esi
f0102982:	8b 4b 5c             	mov    0x5c(%ebx),%ecx
f0102985:	89 34 11             	mov    %esi,(%ecx,%edx,1)
f0102988:	83 c2 04             	add    $0x4,%edx
	e->env_pgdir = page2kva(p);
	p->pp_ref = 0;
	p->pp_link = NULL;
	for(i=0; i<PDX(UTOP); i++)
		e->env_pgdir[i] = 0;
	for(; i<NPDENTRIES; i++)
f010298b:	81 fa 00 10 00 00    	cmp    $0x1000,%edx
f0102991:	75 e6                	jne    f0102979 <env_alloc+0x84>
		e->env_pgdir[i] = kern_pgdir[i];
	p->pp_ref++;
f0102993:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102998:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010299b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029a0:	77 15                	ja     f01029b7 <env_alloc+0xc2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029a2:	50                   	push   %eax
f01029a3:	68 7c 49 10 f0       	push   $0xf010497c
f01029a8:	68 c7 00 00 00       	push   $0xc7
f01029ad:	68 52 50 10 f0       	push   $0xf0105052
f01029b2:	e8 e9 d6 ff ff       	call   f01000a0 <_panic>
f01029b7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01029bd:	83 ca 05             	or     $0x5,%edx
f01029c0:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01029c6:	8b 43 48             	mov    0x48(%ebx),%eax
f01029c9:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01029ce:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01029d3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01029d8:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01029db:	89 da                	mov    %ebx,%edx
f01029dd:	2b 15 48 41 17 f0    	sub    0xf0174148,%edx
f01029e3:	c1 fa 05             	sar    $0x5,%edx
f01029e6:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01029ec:	09 d0                	or     %edx,%eax
f01029ee:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01029f1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029f4:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01029f7:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01029fe:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102a05:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102a0c:	83 ec 04             	sub    $0x4,%esp
f0102a0f:	6a 44                	push   $0x44
f0102a11:	6a 00                	push   $0x0
f0102a13:	53                   	push   %ebx
f0102a14:	e8 da 11 00 00       	call   f0103bf3 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102a19:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102a1f:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102a25:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102a2b:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a32:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102a38:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a3b:	a3 4c 41 17 f0       	mov    %eax,0xf017414c
	*newenv_store = e;
f0102a40:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a43:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a45:	8b 53 48             	mov    0x48(%ebx),%edx
f0102a48:	a1 44 41 17 f0       	mov    0xf0174144,%eax
f0102a4d:	83 c4 10             	add    $0x10,%esp
f0102a50:	85 c0                	test   %eax,%eax
f0102a52:	74 05                	je     f0102a59 <env_alloc+0x164>
f0102a54:	8b 40 48             	mov    0x48(%eax),%eax
f0102a57:	eb 05                	jmp    f0102a5e <env_alloc+0x169>
f0102a59:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a5e:	83 ec 04             	sub    $0x4,%esp
f0102a61:	52                   	push   %edx
f0102a62:	50                   	push   %eax
f0102a63:	68 5d 50 10 f0       	push   $0xf010505d
f0102a68:	e8 af 02 00 00       	call   f0102d1c <cprintf>
	return 0;
f0102a6d:	83 c4 10             	add    $0x10,%esp
f0102a70:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a75:	eb 0c                	jmp    f0102a83 <env_alloc+0x18e>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102a77:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102a7c:	eb 05                	jmp    f0102a83 <env_alloc+0x18e>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102a7e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102a83:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102a86:	5b                   	pop    %ebx
f0102a87:	5e                   	pop    %esi
f0102a88:	5d                   	pop    %ebp
f0102a89:	c3                   	ret    

f0102a8a <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102a8a:	55                   	push   %ebp
f0102a8b:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0102a8d:	5d                   	pop    %ebp
f0102a8e:	c3                   	ret    

f0102a8f <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102a8f:	55                   	push   %ebp
f0102a90:	89 e5                	mov    %esp,%ebp
f0102a92:	57                   	push   %edi
f0102a93:	56                   	push   %esi
f0102a94:	53                   	push   %ebx
f0102a95:	83 ec 1c             	sub    $0x1c,%esp
f0102a98:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102a9b:	8b 15 44 41 17 f0    	mov    0xf0174144,%edx
f0102aa1:	39 fa                	cmp    %edi,%edx
f0102aa3:	75 29                	jne    f0102ace <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102aa5:	a1 08 4e 17 f0       	mov    0xf0174e08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102aaa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102aaf:	77 15                	ja     f0102ac6 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ab1:	50                   	push   %eax
f0102ab2:	68 7c 49 10 f0       	push   $0xf010497c
f0102ab7:	68 76 01 00 00       	push   $0x176
f0102abc:	68 52 50 10 f0       	push   $0xf0105052
f0102ac1:	e8 da d5 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102ac6:	05 00 00 00 10       	add    $0x10000000,%eax
f0102acb:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102ace:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102ad1:	85 d2                	test   %edx,%edx
f0102ad3:	74 05                	je     f0102ada <env_free+0x4b>
f0102ad5:	8b 42 48             	mov    0x48(%edx),%eax
f0102ad8:	eb 05                	jmp    f0102adf <env_free+0x50>
f0102ada:	b8 00 00 00 00       	mov    $0x0,%eax
f0102adf:	83 ec 04             	sub    $0x4,%esp
f0102ae2:	51                   	push   %ecx
f0102ae3:	50                   	push   %eax
f0102ae4:	68 72 50 10 f0       	push   $0xf0105072
f0102ae9:	e8 2e 02 00 00       	call   f0102d1c <cprintf>
f0102aee:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102af1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102af8:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102afb:	89 d0                	mov    %edx,%eax
f0102afd:	c1 e0 02             	shl    $0x2,%eax
f0102b00:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102b03:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102b06:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102b09:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102b0f:	0f 84 a8 00 00 00    	je     f0102bbd <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102b15:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b1b:	89 f0                	mov    %esi,%eax
f0102b1d:	c1 e8 0c             	shr    $0xc,%eax
f0102b20:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102b23:	39 05 04 4e 17 f0    	cmp    %eax,0xf0174e04
f0102b29:	77 15                	ja     f0102b40 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b2b:	56                   	push   %esi
f0102b2c:	68 94 48 10 f0       	push   $0xf0104894
f0102b31:	68 85 01 00 00       	push   $0x185
f0102b36:	68 52 50 10 f0       	push   $0xf0105052
f0102b3b:	e8 60 d5 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102b40:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b43:	c1 e0 16             	shl    $0x16,%eax
f0102b46:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102b49:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102b4e:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102b55:	01 
f0102b56:	74 17                	je     f0102b6f <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102b58:	83 ec 08             	sub    $0x8,%esp
f0102b5b:	89 d8                	mov    %ebx,%eax
f0102b5d:	c1 e0 0c             	shl    $0xc,%eax
f0102b60:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102b63:	50                   	push   %eax
f0102b64:	ff 77 5c             	pushl  0x5c(%edi)
f0102b67:	e8 3a e4 ff ff       	call   f0100fa6 <page_remove>
f0102b6c:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102b6f:	83 c3 01             	add    $0x1,%ebx
f0102b72:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102b78:	75 d4                	jne    f0102b4e <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102b7a:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102b7d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102b80:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b87:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102b8a:	3b 05 04 4e 17 f0    	cmp    0xf0174e04,%eax
f0102b90:	72 14                	jb     f0102ba6 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102b92:	83 ec 04             	sub    $0x4,%esp
f0102b95:	68 a0 49 10 f0       	push   $0xf01049a0
f0102b9a:	6a 4f                	push   $0x4f
f0102b9c:	68 bb 45 10 f0       	push   $0xf01045bb
f0102ba1:	e8 fa d4 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102ba6:	83 ec 0c             	sub    $0xc,%esp
f0102ba9:	a1 0c 4e 17 f0       	mov    0xf0174e0c,%eax
f0102bae:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102bb1:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102bb4:	50                   	push   %eax
f0102bb5:	e8 35 e2 ff ff       	call   f0100def <page_decref>
f0102bba:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102bbd:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102bc1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bc4:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102bc9:	0f 85 29 ff ff ff    	jne    f0102af8 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102bcf:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bd2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bd7:	77 15                	ja     f0102bee <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bd9:	50                   	push   %eax
f0102bda:	68 7c 49 10 f0       	push   $0xf010497c
f0102bdf:	68 93 01 00 00       	push   $0x193
f0102be4:	68 52 50 10 f0       	push   $0xf0105052
f0102be9:	e8 b2 d4 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102bee:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bf5:	05 00 00 00 10       	add    $0x10000000,%eax
f0102bfa:	c1 e8 0c             	shr    $0xc,%eax
f0102bfd:	3b 05 04 4e 17 f0    	cmp    0xf0174e04,%eax
f0102c03:	72 14                	jb     f0102c19 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102c05:	83 ec 04             	sub    $0x4,%esp
f0102c08:	68 a0 49 10 f0       	push   $0xf01049a0
f0102c0d:	6a 4f                	push   $0x4f
f0102c0f:	68 bb 45 10 f0       	push   $0xf01045bb
f0102c14:	e8 87 d4 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102c19:	83 ec 0c             	sub    $0xc,%esp
f0102c1c:	8b 15 0c 4e 17 f0    	mov    0xf0174e0c,%edx
f0102c22:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102c25:	50                   	push   %eax
f0102c26:	e8 c4 e1 ff ff       	call   f0100def <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102c2b:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102c32:	a1 4c 41 17 f0       	mov    0xf017414c,%eax
f0102c37:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102c3a:	89 3d 4c 41 17 f0    	mov    %edi,0xf017414c
}
f0102c40:	83 c4 10             	add    $0x10,%esp
f0102c43:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c46:	5b                   	pop    %ebx
f0102c47:	5e                   	pop    %esi
f0102c48:	5f                   	pop    %edi
f0102c49:	5d                   	pop    %ebp
f0102c4a:	c3                   	ret    

f0102c4b <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102c4b:	55                   	push   %ebp
f0102c4c:	89 e5                	mov    %esp,%ebp
f0102c4e:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102c51:	ff 75 08             	pushl  0x8(%ebp)
f0102c54:	e8 36 fe ff ff       	call   f0102a8f <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102c59:	c7 04 24 1c 50 10 f0 	movl   $0xf010501c,(%esp)
f0102c60:	e8 b7 00 00 00       	call   f0102d1c <cprintf>
f0102c65:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102c68:	83 ec 0c             	sub    $0xc,%esp
f0102c6b:	6a 00                	push   $0x0
f0102c6d:	e8 38 db ff ff       	call   f01007aa <monitor>
f0102c72:	83 c4 10             	add    $0x10,%esp
f0102c75:	eb f1                	jmp    f0102c68 <env_destroy+0x1d>

f0102c77 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102c77:	55                   	push   %ebp
f0102c78:	89 e5                	mov    %esp,%ebp
f0102c7a:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102c7d:	8b 65 08             	mov    0x8(%ebp),%esp
f0102c80:	61                   	popa   
f0102c81:	07                   	pop    %es
f0102c82:	1f                   	pop    %ds
f0102c83:	83 c4 08             	add    $0x8,%esp
f0102c86:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102c87:	68 88 50 10 f0       	push   $0xf0105088
f0102c8c:	68 bb 01 00 00       	push   $0x1bb
f0102c91:	68 52 50 10 f0       	push   $0xf0105052
f0102c96:	e8 05 d4 ff ff       	call   f01000a0 <_panic>

f0102c9b <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102c9b:	55                   	push   %ebp
f0102c9c:	89 e5                	mov    %esp,%ebp
f0102c9e:	83 ec 0c             	sub    $0xc,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f0102ca1:	68 94 50 10 f0       	push   $0xf0105094
f0102ca6:	68 da 01 00 00       	push   $0x1da
f0102cab:	68 52 50 10 f0       	push   $0xf0105052
f0102cb0:	e8 eb d3 ff ff       	call   f01000a0 <_panic>

f0102cb5 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102cb5:	55                   	push   %ebp
f0102cb6:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cb8:	ba 70 00 00 00       	mov    $0x70,%edx
f0102cbd:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cc0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102cc1:	ba 71 00 00 00       	mov    $0x71,%edx
f0102cc6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102cc7:	0f b6 c0             	movzbl %al,%eax
}
f0102cca:	5d                   	pop    %ebp
f0102ccb:	c3                   	ret    

f0102ccc <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ccc:	55                   	push   %ebp
f0102ccd:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ccf:	ba 70 00 00 00       	mov    $0x70,%edx
f0102cd4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cd7:	ee                   	out    %al,(%dx)
f0102cd8:	ba 71 00 00 00       	mov    $0x71,%edx
f0102cdd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ce0:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ce1:	5d                   	pop    %ebp
f0102ce2:	c3                   	ret    

f0102ce3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ce3:	55                   	push   %ebp
f0102ce4:	89 e5                	mov    %esp,%ebp
f0102ce6:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102ce9:	ff 75 08             	pushl  0x8(%ebp)
f0102cec:	e8 16 d9 ff ff       	call   f0100607 <cputchar>
	*cnt++;
}
f0102cf1:	83 c4 10             	add    $0x10,%esp
f0102cf4:	c9                   	leave  
f0102cf5:	c3                   	ret    

f0102cf6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102cf6:	55                   	push   %ebp
f0102cf7:	89 e5                	mov    %esp,%ebp
f0102cf9:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102cfc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d03:	ff 75 0c             	pushl  0xc(%ebp)
f0102d06:	ff 75 08             	pushl  0x8(%ebp)
f0102d09:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d0c:	50                   	push   %eax
f0102d0d:	68 e3 2c 10 f0       	push   $0xf0102ce3
f0102d12:	e8 70 08 00 00       	call   f0103587 <vprintfmt>
	return cnt;
}
f0102d17:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d1a:	c9                   	leave  
f0102d1b:	c3                   	ret    

f0102d1c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d1c:	55                   	push   %ebp
f0102d1d:	89 e5                	mov    %esp,%ebp
f0102d1f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d22:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d25:	50                   	push   %eax
f0102d26:	ff 75 08             	pushl  0x8(%ebp)
f0102d29:	e8 c8 ff ff ff       	call   f0102cf6 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d2e:	c9                   	leave  
f0102d2f:	c3                   	ret    

f0102d30 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102d30:	55                   	push   %ebp
f0102d31:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102d33:	b8 80 49 17 f0       	mov    $0xf0174980,%eax
f0102d38:	c7 05 84 49 17 f0 00 	movl   $0xf0000000,0xf0174984
f0102d3f:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102d42:	66 c7 05 88 49 17 f0 	movw   $0x10,0xf0174988
f0102d49:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102d4b:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102d52:	67 00 
f0102d54:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102d5a:	89 c2                	mov    %eax,%edx
f0102d5c:	c1 ea 10             	shr    $0x10,%edx
f0102d5f:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102d65:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102d6c:	c1 e8 18             	shr    $0x18,%eax
f0102d6f:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102d74:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0102d7b:	b8 28 00 00 00       	mov    $0x28,%eax
f0102d80:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0102d83:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102d88:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102d8b:	5d                   	pop    %ebp
f0102d8c:	c3                   	ret    

f0102d8d <trap_init>:
}


void
trap_init(void)
{
f0102d8d:	55                   	push   %ebp
f0102d8e:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f0102d90:	e8 9b ff ff ff       	call   f0102d30 <trap_init_percpu>
}
f0102d95:	5d                   	pop    %ebp
f0102d96:	c3                   	ret    

f0102d97 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0102d97:	55                   	push   %ebp
f0102d98:	89 e5                	mov    %esp,%ebp
f0102d9a:	53                   	push   %ebx
f0102d9b:	83 ec 0c             	sub    $0xc,%esp
f0102d9e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0102da1:	ff 33                	pushl  (%ebx)
f0102da3:	68 b0 50 10 f0       	push   $0xf01050b0
f0102da8:	e8 6f ff ff ff       	call   f0102d1c <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0102dad:	83 c4 08             	add    $0x8,%esp
f0102db0:	ff 73 04             	pushl  0x4(%ebx)
f0102db3:	68 bf 50 10 f0       	push   $0xf01050bf
f0102db8:	e8 5f ff ff ff       	call   f0102d1c <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0102dbd:	83 c4 08             	add    $0x8,%esp
f0102dc0:	ff 73 08             	pushl  0x8(%ebx)
f0102dc3:	68 ce 50 10 f0       	push   $0xf01050ce
f0102dc8:	e8 4f ff ff ff       	call   f0102d1c <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0102dcd:	83 c4 08             	add    $0x8,%esp
f0102dd0:	ff 73 0c             	pushl  0xc(%ebx)
f0102dd3:	68 dd 50 10 f0       	push   $0xf01050dd
f0102dd8:	e8 3f ff ff ff       	call   f0102d1c <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0102ddd:	83 c4 08             	add    $0x8,%esp
f0102de0:	ff 73 10             	pushl  0x10(%ebx)
f0102de3:	68 ec 50 10 f0       	push   $0xf01050ec
f0102de8:	e8 2f ff ff ff       	call   f0102d1c <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0102ded:	83 c4 08             	add    $0x8,%esp
f0102df0:	ff 73 14             	pushl  0x14(%ebx)
f0102df3:	68 fb 50 10 f0       	push   $0xf01050fb
f0102df8:	e8 1f ff ff ff       	call   f0102d1c <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0102dfd:	83 c4 08             	add    $0x8,%esp
f0102e00:	ff 73 18             	pushl  0x18(%ebx)
f0102e03:	68 0a 51 10 f0       	push   $0xf010510a
f0102e08:	e8 0f ff ff ff       	call   f0102d1c <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0102e0d:	83 c4 08             	add    $0x8,%esp
f0102e10:	ff 73 1c             	pushl  0x1c(%ebx)
f0102e13:	68 19 51 10 f0       	push   $0xf0105119
f0102e18:	e8 ff fe ff ff       	call   f0102d1c <cprintf>
}
f0102e1d:	83 c4 10             	add    $0x10,%esp
f0102e20:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102e23:	c9                   	leave  
f0102e24:	c3                   	ret    

f0102e25 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0102e25:	55                   	push   %ebp
f0102e26:	89 e5                	mov    %esp,%ebp
f0102e28:	56                   	push   %esi
f0102e29:	53                   	push   %ebx
f0102e2a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0102e2d:	83 ec 08             	sub    $0x8,%esp
f0102e30:	53                   	push   %ebx
f0102e31:	68 4f 52 10 f0       	push   $0xf010524f
f0102e36:	e8 e1 fe ff ff       	call   f0102d1c <cprintf>
	print_regs(&tf->tf_regs);
f0102e3b:	89 1c 24             	mov    %ebx,(%esp)
f0102e3e:	e8 54 ff ff ff       	call   f0102d97 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0102e43:	83 c4 08             	add    $0x8,%esp
f0102e46:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0102e4a:	50                   	push   %eax
f0102e4b:	68 6a 51 10 f0       	push   $0xf010516a
f0102e50:	e8 c7 fe ff ff       	call   f0102d1c <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0102e55:	83 c4 08             	add    $0x8,%esp
f0102e58:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0102e5c:	50                   	push   %eax
f0102e5d:	68 7d 51 10 f0       	push   $0xf010517d
f0102e62:	e8 b5 fe ff ff       	call   f0102d1c <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102e67:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0102e6a:	83 c4 10             	add    $0x10,%esp
f0102e6d:	83 f8 13             	cmp    $0x13,%eax
f0102e70:	77 09                	ja     f0102e7b <print_trapframe+0x56>
		return excnames[trapno];
f0102e72:	8b 14 85 20 54 10 f0 	mov    -0xfefabe0(,%eax,4),%edx
f0102e79:	eb 10                	jmp    f0102e8b <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0102e7b:	83 f8 30             	cmp    $0x30,%eax
f0102e7e:	b9 34 51 10 f0       	mov    $0xf0105134,%ecx
f0102e83:	ba 28 51 10 f0       	mov    $0xf0105128,%edx
f0102e88:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102e8b:	83 ec 04             	sub    $0x4,%esp
f0102e8e:	52                   	push   %edx
f0102e8f:	50                   	push   %eax
f0102e90:	68 90 51 10 f0       	push   $0xf0105190
f0102e95:	e8 82 fe ff ff       	call   f0102d1c <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0102e9a:	83 c4 10             	add    $0x10,%esp
f0102e9d:	3b 1d 60 49 17 f0    	cmp    0xf0174960,%ebx
f0102ea3:	75 1a                	jne    f0102ebf <print_trapframe+0x9a>
f0102ea5:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102ea9:	75 14                	jne    f0102ebf <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0102eab:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0102eae:	83 ec 08             	sub    $0x8,%esp
f0102eb1:	50                   	push   %eax
f0102eb2:	68 a2 51 10 f0       	push   $0xf01051a2
f0102eb7:	e8 60 fe ff ff       	call   f0102d1c <cprintf>
f0102ebc:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0102ebf:	83 ec 08             	sub    $0x8,%esp
f0102ec2:	ff 73 2c             	pushl  0x2c(%ebx)
f0102ec5:	68 b1 51 10 f0       	push   $0xf01051b1
f0102eca:	e8 4d fe ff ff       	call   f0102d1c <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0102ecf:	83 c4 10             	add    $0x10,%esp
f0102ed2:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102ed6:	75 49                	jne    f0102f21 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0102ed8:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0102edb:	89 c2                	mov    %eax,%edx
f0102edd:	83 e2 01             	and    $0x1,%edx
f0102ee0:	ba 4e 51 10 f0       	mov    $0xf010514e,%edx
f0102ee5:	b9 43 51 10 f0       	mov    $0xf0105143,%ecx
f0102eea:	0f 44 ca             	cmove  %edx,%ecx
f0102eed:	89 c2                	mov    %eax,%edx
f0102eef:	83 e2 02             	and    $0x2,%edx
f0102ef2:	ba 60 51 10 f0       	mov    $0xf0105160,%edx
f0102ef7:	be 5a 51 10 f0       	mov    $0xf010515a,%esi
f0102efc:	0f 45 d6             	cmovne %esi,%edx
f0102eff:	83 e0 04             	and    $0x4,%eax
f0102f02:	be 7a 52 10 f0       	mov    $0xf010527a,%esi
f0102f07:	b8 65 51 10 f0       	mov    $0xf0105165,%eax
f0102f0c:	0f 44 c6             	cmove  %esi,%eax
f0102f0f:	51                   	push   %ecx
f0102f10:	52                   	push   %edx
f0102f11:	50                   	push   %eax
f0102f12:	68 bf 51 10 f0       	push   $0xf01051bf
f0102f17:	e8 00 fe ff ff       	call   f0102d1c <cprintf>
f0102f1c:	83 c4 10             	add    $0x10,%esp
f0102f1f:	eb 10                	jmp    f0102f31 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0102f21:	83 ec 0c             	sub    $0xc,%esp
f0102f24:	68 60 48 10 f0       	push   $0xf0104860
f0102f29:	e8 ee fd ff ff       	call   f0102d1c <cprintf>
f0102f2e:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0102f31:	83 ec 08             	sub    $0x8,%esp
f0102f34:	ff 73 30             	pushl  0x30(%ebx)
f0102f37:	68 ce 51 10 f0       	push   $0xf01051ce
f0102f3c:	e8 db fd ff ff       	call   f0102d1c <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0102f41:	83 c4 08             	add    $0x8,%esp
f0102f44:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0102f48:	50                   	push   %eax
f0102f49:	68 dd 51 10 f0       	push   $0xf01051dd
f0102f4e:	e8 c9 fd ff ff       	call   f0102d1c <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0102f53:	83 c4 08             	add    $0x8,%esp
f0102f56:	ff 73 38             	pushl  0x38(%ebx)
f0102f59:	68 f0 51 10 f0       	push   $0xf01051f0
f0102f5e:	e8 b9 fd ff ff       	call   f0102d1c <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0102f63:	83 c4 10             	add    $0x10,%esp
f0102f66:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0102f6a:	74 25                	je     f0102f91 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0102f6c:	83 ec 08             	sub    $0x8,%esp
f0102f6f:	ff 73 3c             	pushl  0x3c(%ebx)
f0102f72:	68 ff 51 10 f0       	push   $0xf01051ff
f0102f77:	e8 a0 fd ff ff       	call   f0102d1c <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0102f7c:	83 c4 08             	add    $0x8,%esp
f0102f7f:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0102f83:	50                   	push   %eax
f0102f84:	68 0e 52 10 f0       	push   $0xf010520e
f0102f89:	e8 8e fd ff ff       	call   f0102d1c <cprintf>
f0102f8e:	83 c4 10             	add    $0x10,%esp
	}
}
f0102f91:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102f94:	5b                   	pop    %ebx
f0102f95:	5e                   	pop    %esi
f0102f96:	5d                   	pop    %ebp
f0102f97:	c3                   	ret    

f0102f98 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0102f98:	55                   	push   %ebp
f0102f99:	89 e5                	mov    %esp,%ebp
f0102f9b:	57                   	push   %edi
f0102f9c:	56                   	push   %esi
f0102f9d:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0102fa0:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0102fa1:	9c                   	pushf  
f0102fa2:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0102fa3:	f6 c4 02             	test   $0x2,%ah
f0102fa6:	74 19                	je     f0102fc1 <trap+0x29>
f0102fa8:	68 21 52 10 f0       	push   $0xf0105221
f0102fad:	68 d5 45 10 f0       	push   $0xf01045d5
f0102fb2:	68 a7 00 00 00       	push   $0xa7
f0102fb7:	68 3a 52 10 f0       	push   $0xf010523a
f0102fbc:	e8 df d0 ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0102fc1:	83 ec 08             	sub    $0x8,%esp
f0102fc4:	56                   	push   %esi
f0102fc5:	68 46 52 10 f0       	push   $0xf0105246
f0102fca:	e8 4d fd ff ff       	call   f0102d1c <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0102fcf:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0102fd3:	83 e0 03             	and    $0x3,%eax
f0102fd6:	83 c4 10             	add    $0x10,%esp
f0102fd9:	66 83 f8 03          	cmp    $0x3,%ax
f0102fdd:	75 31                	jne    f0103010 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0102fdf:	a1 44 41 17 f0       	mov    0xf0174144,%eax
f0102fe4:	85 c0                	test   %eax,%eax
f0102fe6:	75 19                	jne    f0103001 <trap+0x69>
f0102fe8:	68 61 52 10 f0       	push   $0xf0105261
f0102fed:	68 d5 45 10 f0       	push   $0xf01045d5
f0102ff2:	68 ad 00 00 00       	push   $0xad
f0102ff7:	68 3a 52 10 f0       	push   $0xf010523a
f0102ffc:	e8 9f d0 ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103001:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103006:	89 c7                	mov    %eax,%edi
f0103008:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010300a:	8b 35 44 41 17 f0    	mov    0xf0174144,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103010:	89 35 60 49 17 f0    	mov    %esi,0xf0174960
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103016:	83 ec 0c             	sub    $0xc,%esp
f0103019:	56                   	push   %esi
f010301a:	e8 06 fe ff ff       	call   f0102e25 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010301f:	83 c4 10             	add    $0x10,%esp
f0103022:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103027:	75 17                	jne    f0103040 <trap+0xa8>
		panic("unhandled trap in kernel");
f0103029:	83 ec 04             	sub    $0x4,%esp
f010302c:	68 68 52 10 f0       	push   $0xf0105268
f0103031:	68 96 00 00 00       	push   $0x96
f0103036:	68 3a 52 10 f0       	push   $0xf010523a
f010303b:	e8 60 d0 ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0103040:	83 ec 0c             	sub    $0xc,%esp
f0103043:	ff 35 44 41 17 f0    	pushl  0xf0174144
f0103049:	e8 fd fb ff ff       	call   f0102c4b <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f010304e:	a1 44 41 17 f0       	mov    0xf0174144,%eax
f0103053:	83 c4 10             	add    $0x10,%esp
f0103056:	85 c0                	test   %eax,%eax
f0103058:	74 06                	je     f0103060 <trap+0xc8>
f010305a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010305e:	74 19                	je     f0103079 <trap+0xe1>
f0103060:	68 c4 53 10 f0       	push   $0xf01053c4
f0103065:	68 d5 45 10 f0       	push   $0xf01045d5
f010306a:	68 bf 00 00 00       	push   $0xbf
f010306f:	68 3a 52 10 f0       	push   $0xf010523a
f0103074:	e8 27 d0 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103079:	83 ec 0c             	sub    $0xc,%esp
f010307c:	50                   	push   %eax
f010307d:	e8 19 fc ff ff       	call   f0102c9b <env_run>

f0103082 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103082:	55                   	push   %ebp
f0103083:	89 e5                	mov    %esp,%ebp
f0103085:	53                   	push   %ebx
f0103086:	83 ec 04             	sub    $0x4,%esp
f0103089:	8b 5d 08             	mov    0x8(%ebp),%ebx

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f010308c:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010308f:	ff 73 30             	pushl  0x30(%ebx)
f0103092:	50                   	push   %eax
f0103093:	a1 44 41 17 f0       	mov    0xf0174144,%eax
f0103098:	ff 70 48             	pushl  0x48(%eax)
f010309b:	68 f0 53 10 f0       	push   $0xf01053f0
f01030a0:	e8 77 fc ff ff       	call   f0102d1c <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01030a5:	89 1c 24             	mov    %ebx,(%esp)
f01030a8:	e8 78 fd ff ff       	call   f0102e25 <print_trapframe>
	env_destroy(curenv);
f01030ad:	83 c4 04             	add    $0x4,%esp
f01030b0:	ff 35 44 41 17 f0    	pushl  0xf0174144
f01030b6:	e8 90 fb ff ff       	call   f0102c4b <env_destroy>
}
f01030bb:	83 c4 10             	add    $0x10,%esp
f01030be:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030c1:	c9                   	leave  
f01030c2:	c3                   	ret    

f01030c3 <syscall>:
f01030c3:	55                   	push   %ebp
f01030c4:	89 e5                	mov    %esp,%ebp
f01030c6:	83 ec 0c             	sub    $0xc,%esp
f01030c9:	68 70 54 10 f0       	push   $0xf0105470
f01030ce:	6a 49                	push   $0x49
f01030d0:	68 88 54 10 f0       	push   $0xf0105488
f01030d5:	e8 c6 cf ff ff       	call   f01000a0 <_panic>

f01030da <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01030da:	55                   	push   %ebp
f01030db:	89 e5                	mov    %esp,%ebp
f01030dd:	57                   	push   %edi
f01030de:	56                   	push   %esi
f01030df:	53                   	push   %ebx
f01030e0:	83 ec 14             	sub    $0x14,%esp
f01030e3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01030e6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01030e9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01030ec:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01030ef:	8b 1a                	mov    (%edx),%ebx
f01030f1:	8b 01                	mov    (%ecx),%eax
f01030f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01030f6:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01030fd:	eb 7f                	jmp    f010317e <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01030ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103102:	01 d8                	add    %ebx,%eax
f0103104:	89 c6                	mov    %eax,%esi
f0103106:	c1 ee 1f             	shr    $0x1f,%esi
f0103109:	01 c6                	add    %eax,%esi
f010310b:	d1 fe                	sar    %esi
f010310d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103110:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103113:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103116:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103118:	eb 03                	jmp    f010311d <stab_binsearch+0x43>
			m--;
f010311a:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010311d:	39 c3                	cmp    %eax,%ebx
f010311f:	7f 0d                	jg     f010312e <stab_binsearch+0x54>
f0103121:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103125:	83 ea 0c             	sub    $0xc,%edx
f0103128:	39 f9                	cmp    %edi,%ecx
f010312a:	75 ee                	jne    f010311a <stab_binsearch+0x40>
f010312c:	eb 05                	jmp    f0103133 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010312e:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103131:	eb 4b                	jmp    f010317e <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103133:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103136:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103139:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010313d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103140:	76 11                	jbe    f0103153 <stab_binsearch+0x79>
			*region_left = m;
f0103142:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103145:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103147:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010314a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103151:	eb 2b                	jmp    f010317e <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103153:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103156:	73 14                	jae    f010316c <stab_binsearch+0x92>
			*region_right = m - 1;
f0103158:	83 e8 01             	sub    $0x1,%eax
f010315b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010315e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103161:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103163:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010316a:	eb 12                	jmp    f010317e <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010316c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010316f:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103171:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103175:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103177:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010317e:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103181:	0f 8e 78 ff ff ff    	jle    f01030ff <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103187:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010318b:	75 0f                	jne    f010319c <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010318d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103190:	8b 00                	mov    (%eax),%eax
f0103192:	83 e8 01             	sub    $0x1,%eax
f0103195:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103198:	89 06                	mov    %eax,(%esi)
f010319a:	eb 2c                	jmp    f01031c8 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010319c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010319f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01031a1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031a4:	8b 0e                	mov    (%esi),%ecx
f01031a6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01031a9:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01031ac:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01031af:	eb 03                	jmp    f01031b4 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01031b1:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01031b4:	39 c8                	cmp    %ecx,%eax
f01031b6:	7e 0b                	jle    f01031c3 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01031b8:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01031bc:	83 ea 0c             	sub    $0xc,%edx
f01031bf:	39 df                	cmp    %ebx,%edi
f01031c1:	75 ee                	jne    f01031b1 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01031c3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031c6:	89 06                	mov    %eax,(%esi)
	}
}
f01031c8:	83 c4 14             	add    $0x14,%esp
f01031cb:	5b                   	pop    %ebx
f01031cc:	5e                   	pop    %esi
f01031cd:	5f                   	pop    %edi
f01031ce:	5d                   	pop    %ebp
f01031cf:	c3                   	ret    

f01031d0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01031d0:	55                   	push   %ebp
f01031d1:	89 e5                	mov    %esp,%ebp
f01031d3:	57                   	push   %edi
f01031d4:	56                   	push   %esi
f01031d5:	53                   	push   %ebx
f01031d6:	83 ec 3c             	sub    $0x3c,%esp
f01031d9:	8b 75 08             	mov    0x8(%ebp),%esi
f01031dc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01031df:	c7 03 97 54 10 f0    	movl   $0xf0105497,(%ebx)
	info->eip_line = 0;
f01031e5:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01031ec:	c7 43 08 97 54 10 f0 	movl   $0xf0105497,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01031f3:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01031fa:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01031fd:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103204:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010320a:	77 21                	ja     f010322d <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f010320c:	a1 00 00 20 00       	mov    0x200000,%eax
f0103211:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0103214:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103219:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f010321f:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0103222:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0103228:	89 7d bc             	mov    %edi,-0x44(%ebp)
f010322b:	eb 1a                	jmp    f0103247 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010322d:	c7 45 bc 72 f1 10 f0 	movl   $0xf010f172,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103234:	c7 45 b8 f9 c7 10 f0 	movl   $0xf010c7f9,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010323b:	b8 f8 c7 10 f0       	mov    $0xf010c7f8,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103240:	c7 45 c0 d0 56 10 f0 	movl   $0xf01056d0,-0x40(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103247:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010324a:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f010324d:	0f 83 e8 01 00 00    	jae    f010343b <debuginfo_eip+0x26b>
f0103253:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103257:	0f 85 e5 01 00 00    	jne    f0103442 <debuginfo_eip+0x272>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010325d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103264:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103267:	29 f8                	sub    %edi,%eax
f0103269:	c1 f8 02             	sar    $0x2,%eax
f010326c:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103272:	83 e8 01             	sub    $0x1,%eax
f0103275:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103278:	56                   	push   %esi
f0103279:	6a 64                	push   $0x64
f010327b:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010327e:	89 c1                	mov    %eax,%ecx
f0103280:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103283:	89 f8                	mov    %edi,%eax
f0103285:	e8 50 fe ff ff       	call   f01030da <stab_binsearch>
	if (lfile == 0)
f010328a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010328d:	83 c4 08             	add    $0x8,%esp
f0103290:	85 c0                	test   %eax,%eax
f0103292:	0f 84 b1 01 00 00    	je     f0103449 <debuginfo_eip+0x279>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103298:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010329b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010329e:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01032a1:	56                   	push   %esi
f01032a2:	6a 24                	push   $0x24
f01032a4:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01032a7:	89 c1                	mov    %eax,%ecx
f01032a9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01032ac:	89 f8                	mov    %edi,%eax
f01032ae:	e8 27 fe ff ff       	call   f01030da <stab_binsearch>

	if (lfun <= rfun) {
f01032b3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01032b6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032b9:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f01032bc:	83 c4 08             	add    $0x8,%esp
f01032bf:	39 d0                	cmp    %edx,%eax
f01032c1:	7f 2b                	jg     f01032ee <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01032c3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01032c6:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f01032c9:	8b 11                	mov    (%ecx),%edx
f01032cb:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01032ce:	2b 7d b8             	sub    -0x48(%ebp),%edi
f01032d1:	39 fa                	cmp    %edi,%edx
f01032d3:	73 06                	jae    f01032db <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01032d5:	03 55 b8             	add    -0x48(%ebp),%edx
f01032d8:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01032db:	8b 51 08             	mov    0x8(%ecx),%edx
f01032de:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01032e1:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01032e3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01032e6:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01032e9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01032ec:	eb 0f                	jmp    f01032fd <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01032ee:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01032f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032f4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01032f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032fa:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01032fd:	83 ec 08             	sub    $0x8,%esp
f0103300:	6a 3a                	push   $0x3a
f0103302:	ff 73 08             	pushl  0x8(%ebx)
f0103305:	e8 cd 08 00 00       	call   f0103bd7 <strfind>
f010330a:	2b 43 08             	sub    0x8(%ebx),%eax
f010330d:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

    if (lfun <= rfun) {
f0103310:	83 c4 10             	add    $0x10,%esp
f0103313:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103316:	39 45 dc             	cmp    %eax,-0x24(%ebp)
f0103319:	7f 24                	jg     f010333f <debuginfo_eip+0x16f>
        // If lfun <= rfun, it's a function span search.
        // In this case, n_value is in order!
        // So use binary search.
        stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010331b:	83 ec 08             	sub    $0x8,%esp
f010331e:	56                   	push   %esi
f010331f:	6a 44                	push   $0x44
f0103321:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103324:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103327:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010332a:	e8 ab fd ff ff       	call   f01030da <stab_binsearch>

        if (lline > rline)
f010332f:	83 c4 10             	add    $0x10,%esp
f0103332:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103335:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0103338:	7e 48                	jle    f0103382 <debuginfo_eip+0x1b2>
f010333a:	e9 11 01 00 00       	jmp    f0103450 <debuginfo_eip+0x280>
        // Note that if lfun > rfun, lline, rline == lfile, rfile,
        // which means a file span search.
        // In this case, n_value is not in order!
        // Cannot use binary search, so just sequential search.
        int index;
        for (index = lline; index <= rline; ++index)
f010333f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103342:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103345:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0103348:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010334b:	8d 04 87             	lea    (%edi,%eax,4),%eax
f010334e:	eb 24                	jmp    f0103374 <debuginfo_eip+0x1a4>
            if (stabs[index].n_type == N_SLINE) {
f0103350:	80 78 04 44          	cmpb   $0x44,0x4(%eax)
f0103354:	75 18                	jne    f010336e <debuginfo_eip+0x19e>
                uintptr_t stab_addr = stabs[index].n_value;
f0103356:	8b 78 08             	mov    0x8(%eax),%edi
                if (stab_addr == addr) {
f0103359:	39 fe                	cmp    %edi,%esi
f010335b:	75 05                	jne    f0103362 <debuginfo_eip+0x192>
                    lline = index;
f010335d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                    break;
f0103360:	eb 20                	jmp    f0103382 <debuginfo_eip+0x1b2>
                } else if (stab_addr > addr) {
f0103362:	39 fe                	cmp    %edi,%esi
f0103364:	73 08                	jae    f010336e <debuginfo_eip+0x19e>
                    lline = index - 1;
f0103366:	83 ea 01             	sub    $0x1,%edx
f0103369:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                    break;
f010336c:	eb 14                	jmp    f0103382 <debuginfo_eip+0x1b2>
        // Note that if lfun > rfun, lline, rline == lfile, rfile,
        // which means a file span search.
        // In this case, n_value is not in order!
        // Cannot use binary search, so just sequential search.
        int index;
        for (index = lline; index <= rline; ++index)
f010336e:	83 c2 01             	add    $0x1,%edx
f0103371:	83 c0 0c             	add    $0xc,%eax
f0103374:	39 ca                	cmp    %ecx,%edx
f0103376:	7e d8                	jle    f0103350 <debuginfo_eip+0x180>
                    break;
                }
            }

        if (index > rline)
            return -1;
f0103378:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010337d:	e9 da 00 00 00       	jmp    f010345c <debuginfo_eip+0x28c>
    }

    info->eip_line = stabs[lline].n_desc;
f0103382:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103385:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103388:	8b 75 c0             	mov    -0x40(%ebp),%esi
f010338b:	8d 14 96             	lea    (%esi,%edx,4),%edx
f010338e:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0103392:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103395:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103398:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010339c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010339f:	eb 0a                	jmp    f01033ab <debuginfo_eip+0x1db>
f01033a1:	83 e8 01             	sub    $0x1,%eax
f01033a4:	83 ea 0c             	sub    $0xc,%edx
f01033a7:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01033ab:	39 c7                	cmp    %eax,%edi
f01033ad:	7e 05                	jle    f01033b4 <debuginfo_eip+0x1e4>
f01033af:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033b2:	eb 47                	jmp    f01033fb <debuginfo_eip+0x22b>
	       && stabs[lline].n_type != N_SOL
f01033b4:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01033b8:	80 f9 84             	cmp    $0x84,%cl
f01033bb:	75 0e                	jne    f01033cb <debuginfo_eip+0x1fb>
f01033bd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033c0:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01033c4:	74 1c                	je     f01033e2 <debuginfo_eip+0x212>
f01033c6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01033c9:	eb 17                	jmp    f01033e2 <debuginfo_eip+0x212>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01033cb:	80 f9 64             	cmp    $0x64,%cl
f01033ce:	75 d1                	jne    f01033a1 <debuginfo_eip+0x1d1>
f01033d0:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01033d4:	74 cb                	je     f01033a1 <debuginfo_eip+0x1d1>
f01033d6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033d9:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01033dd:	74 03                	je     f01033e2 <debuginfo_eip+0x212>
f01033df:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01033e2:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01033e5:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01033e8:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01033eb:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01033ee:	8b 75 b8             	mov    -0x48(%ebp),%esi
f01033f1:	29 f0                	sub    %esi,%eax
f01033f3:	39 c2                	cmp    %eax,%edx
f01033f5:	73 04                	jae    f01033fb <debuginfo_eip+0x22b>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01033f7:	01 f2                	add    %esi,%edx
f01033f9:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01033fb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01033fe:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103401:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103406:	39 f2                	cmp    %esi,%edx
f0103408:	7d 52                	jge    f010345c <debuginfo_eip+0x28c>
		for (lline = lfun + 1;
f010340a:	83 c2 01             	add    $0x1,%edx
f010340d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103410:	89 d0                	mov    %edx,%eax
f0103412:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103415:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103418:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010341b:	eb 04                	jmp    f0103421 <debuginfo_eip+0x251>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010341d:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103421:	39 c6                	cmp    %eax,%esi
f0103423:	7e 32                	jle    f0103457 <debuginfo_eip+0x287>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103425:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103429:	83 c0 01             	add    $0x1,%eax
f010342c:	83 c2 0c             	add    $0xc,%edx
f010342f:	80 f9 a0             	cmp    $0xa0,%cl
f0103432:	74 e9                	je     f010341d <debuginfo_eip+0x24d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103434:	b8 00 00 00 00       	mov    $0x0,%eax
f0103439:	eb 21                	jmp    f010345c <debuginfo_eip+0x28c>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010343b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103440:	eb 1a                	jmp    f010345c <debuginfo_eip+0x28c>
f0103442:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103447:	eb 13                	jmp    f010345c <debuginfo_eip+0x28c>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103449:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010344e:	eb 0c                	jmp    f010345c <debuginfo_eip+0x28c>
        // In this case, n_value is in order!
        // So use binary search.
        stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);

        if (lline > rline)
            return -1;
f0103450:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103455:	eb 05                	jmp    f010345c <debuginfo_eip+0x28c>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103457:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010345c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010345f:	5b                   	pop    %ebx
f0103460:	5e                   	pop    %esi
f0103461:	5f                   	pop    %edi
f0103462:	5d                   	pop    %ebp
f0103463:	c3                   	ret    

f0103464 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103464:	55                   	push   %ebp
f0103465:	89 e5                	mov    %esp,%ebp
f0103467:	57                   	push   %edi
f0103468:	56                   	push   %esi
f0103469:	53                   	push   %ebx
f010346a:	83 ec 1c             	sub    $0x1c,%esp
f010346d:	89 c7                	mov    %eax,%edi
f010346f:	89 d6                	mov    %edx,%esi
f0103471:	8b 45 08             	mov    0x8(%ebp),%eax
f0103474:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103477:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010347a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010347d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103480:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103485:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103488:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010348b:	39 d3                	cmp    %edx,%ebx
f010348d:	72 05                	jb     f0103494 <printnum+0x30>
f010348f:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103492:	77 45                	ja     f01034d9 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103494:	83 ec 0c             	sub    $0xc,%esp
f0103497:	ff 75 18             	pushl  0x18(%ebp)
f010349a:	8b 45 14             	mov    0x14(%ebp),%eax
f010349d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01034a0:	53                   	push   %ebx
f01034a1:	ff 75 10             	pushl  0x10(%ebp)
f01034a4:	83 ec 08             	sub    $0x8,%esp
f01034a7:	ff 75 e4             	pushl  -0x1c(%ebp)
f01034aa:	ff 75 e0             	pushl  -0x20(%ebp)
f01034ad:	ff 75 dc             	pushl  -0x24(%ebp)
f01034b0:	ff 75 d8             	pushl  -0x28(%ebp)
f01034b3:	e8 48 09 00 00       	call   f0103e00 <__udivdi3>
f01034b8:	83 c4 18             	add    $0x18,%esp
f01034bb:	52                   	push   %edx
f01034bc:	50                   	push   %eax
f01034bd:	89 f2                	mov    %esi,%edx
f01034bf:	89 f8                	mov    %edi,%eax
f01034c1:	e8 9e ff ff ff       	call   f0103464 <printnum>
f01034c6:	83 c4 20             	add    $0x20,%esp
f01034c9:	eb 18                	jmp    f01034e3 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01034cb:	83 ec 08             	sub    $0x8,%esp
f01034ce:	56                   	push   %esi
f01034cf:	ff 75 18             	pushl  0x18(%ebp)
f01034d2:	ff d7                	call   *%edi
f01034d4:	83 c4 10             	add    $0x10,%esp
f01034d7:	eb 03                	jmp    f01034dc <printnum+0x78>
f01034d9:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01034dc:	83 eb 01             	sub    $0x1,%ebx
f01034df:	85 db                	test   %ebx,%ebx
f01034e1:	7f e8                	jg     f01034cb <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01034e3:	83 ec 08             	sub    $0x8,%esp
f01034e6:	56                   	push   %esi
f01034e7:	83 ec 04             	sub    $0x4,%esp
f01034ea:	ff 75 e4             	pushl  -0x1c(%ebp)
f01034ed:	ff 75 e0             	pushl  -0x20(%ebp)
f01034f0:	ff 75 dc             	pushl  -0x24(%ebp)
f01034f3:	ff 75 d8             	pushl  -0x28(%ebp)
f01034f6:	e8 35 0a 00 00       	call   f0103f30 <__umoddi3>
f01034fb:	83 c4 14             	add    $0x14,%esp
f01034fe:	0f be 80 a1 54 10 f0 	movsbl -0xfefab5f(%eax),%eax
f0103505:	50                   	push   %eax
f0103506:	ff d7                	call   *%edi
}
f0103508:	83 c4 10             	add    $0x10,%esp
f010350b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010350e:	5b                   	pop    %ebx
f010350f:	5e                   	pop    %esi
f0103510:	5f                   	pop    %edi
f0103511:	5d                   	pop    %ebp
f0103512:	c3                   	ret    

f0103513 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103513:	55                   	push   %ebp
f0103514:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103516:	83 fa 01             	cmp    $0x1,%edx
f0103519:	7e 0e                	jle    f0103529 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010351b:	8b 10                	mov    (%eax),%edx
f010351d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103520:	89 08                	mov    %ecx,(%eax)
f0103522:	8b 02                	mov    (%edx),%eax
f0103524:	8b 52 04             	mov    0x4(%edx),%edx
f0103527:	eb 22                	jmp    f010354b <getuint+0x38>
	else if (lflag)
f0103529:	85 d2                	test   %edx,%edx
f010352b:	74 10                	je     f010353d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010352d:	8b 10                	mov    (%eax),%edx
f010352f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103532:	89 08                	mov    %ecx,(%eax)
f0103534:	8b 02                	mov    (%edx),%eax
f0103536:	ba 00 00 00 00       	mov    $0x0,%edx
f010353b:	eb 0e                	jmp    f010354b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010353d:	8b 10                	mov    (%eax),%edx
f010353f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103542:	89 08                	mov    %ecx,(%eax)
f0103544:	8b 02                	mov    (%edx),%eax
f0103546:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010354b:	5d                   	pop    %ebp
f010354c:	c3                   	ret    

f010354d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010354d:	55                   	push   %ebp
f010354e:	89 e5                	mov    %esp,%ebp
f0103550:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103553:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103557:	8b 10                	mov    (%eax),%edx
f0103559:	3b 50 04             	cmp    0x4(%eax),%edx
f010355c:	73 0a                	jae    f0103568 <sprintputch+0x1b>
		*b->buf++ = ch;
f010355e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103561:	89 08                	mov    %ecx,(%eax)
f0103563:	8b 45 08             	mov    0x8(%ebp),%eax
f0103566:	88 02                	mov    %al,(%edx)
}
f0103568:	5d                   	pop    %ebp
f0103569:	c3                   	ret    

f010356a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010356a:	55                   	push   %ebp
f010356b:	89 e5                	mov    %esp,%ebp
f010356d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103570:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103573:	50                   	push   %eax
f0103574:	ff 75 10             	pushl  0x10(%ebp)
f0103577:	ff 75 0c             	pushl  0xc(%ebp)
f010357a:	ff 75 08             	pushl  0x8(%ebp)
f010357d:	e8 05 00 00 00       	call   f0103587 <vprintfmt>
	va_end(ap);
}
f0103582:	83 c4 10             	add    $0x10,%esp
f0103585:	c9                   	leave  
f0103586:	c3                   	ret    

f0103587 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103587:	55                   	push   %ebp
f0103588:	89 e5                	mov    %esp,%ebp
f010358a:	57                   	push   %edi
f010358b:	56                   	push   %esi
f010358c:	53                   	push   %ebx
f010358d:	83 ec 2c             	sub    $0x2c,%esp
f0103590:	8b 75 08             	mov    0x8(%ebp),%esi
f0103593:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103596:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103599:	eb 12                	jmp    f01035ad <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010359b:	85 c0                	test   %eax,%eax
f010359d:	0f 84 89 03 00 00    	je     f010392c <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f01035a3:	83 ec 08             	sub    $0x8,%esp
f01035a6:	53                   	push   %ebx
f01035a7:	50                   	push   %eax
f01035a8:	ff d6                	call   *%esi
f01035aa:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01035ad:	83 c7 01             	add    $0x1,%edi
f01035b0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01035b4:	83 f8 25             	cmp    $0x25,%eax
f01035b7:	75 e2                	jne    f010359b <vprintfmt+0x14>
f01035b9:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01035bd:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01035c4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01035cb:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01035d2:	ba 00 00 00 00       	mov    $0x0,%edx
f01035d7:	eb 07                	jmp    f01035e0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01035dc:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035e0:	8d 47 01             	lea    0x1(%edi),%eax
f01035e3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01035e6:	0f b6 07             	movzbl (%edi),%eax
f01035e9:	0f b6 c8             	movzbl %al,%ecx
f01035ec:	83 e8 23             	sub    $0x23,%eax
f01035ef:	3c 55                	cmp    $0x55,%al
f01035f1:	0f 87 1a 03 00 00    	ja     f0103911 <vprintfmt+0x38a>
f01035f7:	0f b6 c0             	movzbl %al,%eax
f01035fa:	ff 24 85 40 55 10 f0 	jmp    *-0xfefaac0(,%eax,4)
f0103601:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103604:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103608:	eb d6                	jmp    f01035e0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010360a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010360d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103612:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103615:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103618:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f010361c:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f010361f:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103622:	83 fa 09             	cmp    $0x9,%edx
f0103625:	77 39                	ja     f0103660 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103627:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010362a:	eb e9                	jmp    f0103615 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010362c:	8b 45 14             	mov    0x14(%ebp),%eax
f010362f:	8d 48 04             	lea    0x4(%eax),%ecx
f0103632:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103635:	8b 00                	mov    (%eax),%eax
f0103637:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010363a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010363d:	eb 27                	jmp    f0103666 <vprintfmt+0xdf>
f010363f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103642:	85 c0                	test   %eax,%eax
f0103644:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103649:	0f 49 c8             	cmovns %eax,%ecx
f010364c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010364f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103652:	eb 8c                	jmp    f01035e0 <vprintfmt+0x59>
f0103654:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103657:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010365e:	eb 80                	jmp    f01035e0 <vprintfmt+0x59>
f0103660:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103663:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103666:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010366a:	0f 89 70 ff ff ff    	jns    f01035e0 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103670:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103673:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103676:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010367d:	e9 5e ff ff ff       	jmp    f01035e0 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103682:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103685:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103688:	e9 53 ff ff ff       	jmp    f01035e0 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010368d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103690:	8d 50 04             	lea    0x4(%eax),%edx
f0103693:	89 55 14             	mov    %edx,0x14(%ebp)
f0103696:	83 ec 08             	sub    $0x8,%esp
f0103699:	53                   	push   %ebx
f010369a:	ff 30                	pushl  (%eax)
f010369c:	ff d6                	call   *%esi
			break;
f010369e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01036a4:	e9 04 ff ff ff       	jmp    f01035ad <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01036a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01036ac:	8d 50 04             	lea    0x4(%eax),%edx
f01036af:	89 55 14             	mov    %edx,0x14(%ebp)
f01036b2:	8b 00                	mov    (%eax),%eax
f01036b4:	99                   	cltd   
f01036b5:	31 d0                	xor    %edx,%eax
f01036b7:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01036b9:	83 f8 07             	cmp    $0x7,%eax
f01036bc:	7f 0b                	jg     f01036c9 <vprintfmt+0x142>
f01036be:	8b 14 85 a0 56 10 f0 	mov    -0xfefa960(,%eax,4),%edx
f01036c5:	85 d2                	test   %edx,%edx
f01036c7:	75 18                	jne    f01036e1 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f01036c9:	50                   	push   %eax
f01036ca:	68 b9 54 10 f0       	push   $0xf01054b9
f01036cf:	53                   	push   %ebx
f01036d0:	56                   	push   %esi
f01036d1:	e8 94 fe ff ff       	call   f010356a <printfmt>
f01036d6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01036dc:	e9 cc fe ff ff       	jmp    f01035ad <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01036e1:	52                   	push   %edx
f01036e2:	68 e7 45 10 f0       	push   $0xf01045e7
f01036e7:	53                   	push   %ebx
f01036e8:	56                   	push   %esi
f01036e9:	e8 7c fe ff ff       	call   f010356a <printfmt>
f01036ee:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036f1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01036f4:	e9 b4 fe ff ff       	jmp    f01035ad <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01036f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01036fc:	8d 50 04             	lea    0x4(%eax),%edx
f01036ff:	89 55 14             	mov    %edx,0x14(%ebp)
f0103702:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103704:	85 ff                	test   %edi,%edi
f0103706:	b8 b2 54 10 f0       	mov    $0xf01054b2,%eax
f010370b:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010370e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103712:	0f 8e 94 00 00 00    	jle    f01037ac <vprintfmt+0x225>
f0103718:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010371c:	0f 84 98 00 00 00    	je     f01037ba <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103722:	83 ec 08             	sub    $0x8,%esp
f0103725:	ff 75 d0             	pushl  -0x30(%ebp)
f0103728:	57                   	push   %edi
f0103729:	e8 5f 03 00 00       	call   f0103a8d <strnlen>
f010372e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103731:	29 c1                	sub    %eax,%ecx
f0103733:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103736:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103739:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010373d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103740:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103743:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103745:	eb 0f                	jmp    f0103756 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103747:	83 ec 08             	sub    $0x8,%esp
f010374a:	53                   	push   %ebx
f010374b:	ff 75 e0             	pushl  -0x20(%ebp)
f010374e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103750:	83 ef 01             	sub    $0x1,%edi
f0103753:	83 c4 10             	add    $0x10,%esp
f0103756:	85 ff                	test   %edi,%edi
f0103758:	7f ed                	jg     f0103747 <vprintfmt+0x1c0>
f010375a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010375d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103760:	85 c9                	test   %ecx,%ecx
f0103762:	b8 00 00 00 00       	mov    $0x0,%eax
f0103767:	0f 49 c1             	cmovns %ecx,%eax
f010376a:	29 c1                	sub    %eax,%ecx
f010376c:	89 75 08             	mov    %esi,0x8(%ebp)
f010376f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103772:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103775:	89 cb                	mov    %ecx,%ebx
f0103777:	eb 4d                	jmp    f01037c6 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103779:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010377d:	74 1b                	je     f010379a <vprintfmt+0x213>
f010377f:	0f be c0             	movsbl %al,%eax
f0103782:	83 e8 20             	sub    $0x20,%eax
f0103785:	83 f8 5e             	cmp    $0x5e,%eax
f0103788:	76 10                	jbe    f010379a <vprintfmt+0x213>
					putch('?', putdat);
f010378a:	83 ec 08             	sub    $0x8,%esp
f010378d:	ff 75 0c             	pushl  0xc(%ebp)
f0103790:	6a 3f                	push   $0x3f
f0103792:	ff 55 08             	call   *0x8(%ebp)
f0103795:	83 c4 10             	add    $0x10,%esp
f0103798:	eb 0d                	jmp    f01037a7 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f010379a:	83 ec 08             	sub    $0x8,%esp
f010379d:	ff 75 0c             	pushl  0xc(%ebp)
f01037a0:	52                   	push   %edx
f01037a1:	ff 55 08             	call   *0x8(%ebp)
f01037a4:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01037a7:	83 eb 01             	sub    $0x1,%ebx
f01037aa:	eb 1a                	jmp    f01037c6 <vprintfmt+0x23f>
f01037ac:	89 75 08             	mov    %esi,0x8(%ebp)
f01037af:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01037b2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01037b5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01037b8:	eb 0c                	jmp    f01037c6 <vprintfmt+0x23f>
f01037ba:	89 75 08             	mov    %esi,0x8(%ebp)
f01037bd:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01037c0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01037c3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01037c6:	83 c7 01             	add    $0x1,%edi
f01037c9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01037cd:	0f be d0             	movsbl %al,%edx
f01037d0:	85 d2                	test   %edx,%edx
f01037d2:	74 23                	je     f01037f7 <vprintfmt+0x270>
f01037d4:	85 f6                	test   %esi,%esi
f01037d6:	78 a1                	js     f0103779 <vprintfmt+0x1f2>
f01037d8:	83 ee 01             	sub    $0x1,%esi
f01037db:	79 9c                	jns    f0103779 <vprintfmt+0x1f2>
f01037dd:	89 df                	mov    %ebx,%edi
f01037df:	8b 75 08             	mov    0x8(%ebp),%esi
f01037e2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01037e5:	eb 18                	jmp    f01037ff <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01037e7:	83 ec 08             	sub    $0x8,%esp
f01037ea:	53                   	push   %ebx
f01037eb:	6a 20                	push   $0x20
f01037ed:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01037ef:	83 ef 01             	sub    $0x1,%edi
f01037f2:	83 c4 10             	add    $0x10,%esp
f01037f5:	eb 08                	jmp    f01037ff <vprintfmt+0x278>
f01037f7:	89 df                	mov    %ebx,%edi
f01037f9:	8b 75 08             	mov    0x8(%ebp),%esi
f01037fc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01037ff:	85 ff                	test   %edi,%edi
f0103801:	7f e4                	jg     f01037e7 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103803:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103806:	e9 a2 fd ff ff       	jmp    f01035ad <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010380b:	83 fa 01             	cmp    $0x1,%edx
f010380e:	7e 16                	jle    f0103826 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103810:	8b 45 14             	mov    0x14(%ebp),%eax
f0103813:	8d 50 08             	lea    0x8(%eax),%edx
f0103816:	89 55 14             	mov    %edx,0x14(%ebp)
f0103819:	8b 50 04             	mov    0x4(%eax),%edx
f010381c:	8b 00                	mov    (%eax),%eax
f010381e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103821:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103824:	eb 32                	jmp    f0103858 <vprintfmt+0x2d1>
	else if (lflag)
f0103826:	85 d2                	test   %edx,%edx
f0103828:	74 18                	je     f0103842 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f010382a:	8b 45 14             	mov    0x14(%ebp),%eax
f010382d:	8d 50 04             	lea    0x4(%eax),%edx
f0103830:	89 55 14             	mov    %edx,0x14(%ebp)
f0103833:	8b 00                	mov    (%eax),%eax
f0103835:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103838:	89 c1                	mov    %eax,%ecx
f010383a:	c1 f9 1f             	sar    $0x1f,%ecx
f010383d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103840:	eb 16                	jmp    f0103858 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103842:	8b 45 14             	mov    0x14(%ebp),%eax
f0103845:	8d 50 04             	lea    0x4(%eax),%edx
f0103848:	89 55 14             	mov    %edx,0x14(%ebp)
f010384b:	8b 00                	mov    (%eax),%eax
f010384d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103850:	89 c1                	mov    %eax,%ecx
f0103852:	c1 f9 1f             	sar    $0x1f,%ecx
f0103855:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103858:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010385b:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010385e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103863:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103867:	79 74                	jns    f01038dd <vprintfmt+0x356>
				putch('-', putdat);
f0103869:	83 ec 08             	sub    $0x8,%esp
f010386c:	53                   	push   %ebx
f010386d:	6a 2d                	push   $0x2d
f010386f:	ff d6                	call   *%esi
				num = -(long long) num;
f0103871:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103874:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103877:	f7 d8                	neg    %eax
f0103879:	83 d2 00             	adc    $0x0,%edx
f010387c:	f7 da                	neg    %edx
f010387e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103881:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103886:	eb 55                	jmp    f01038dd <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103888:	8d 45 14             	lea    0x14(%ebp),%eax
f010388b:	e8 83 fc ff ff       	call   f0103513 <getuint>
			base = 10;
f0103890:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103895:	eb 46                	jmp    f01038dd <vprintfmt+0x356>
		case 'o':
			// Replace this with your code.
//			putch('X', putdat);
//			putch('X', putdat);
//			putch('X', putdat);
			num = getuint(&ap, lflag);
f0103897:	8d 45 14             	lea    0x14(%ebp),%eax
f010389a:	e8 74 fc ff ff       	call   f0103513 <getuint>
			base = 8;
f010389f:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01038a4:	eb 37                	jmp    f01038dd <vprintfmt+0x356>
//			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01038a6:	83 ec 08             	sub    $0x8,%esp
f01038a9:	53                   	push   %ebx
f01038aa:	6a 30                	push   $0x30
f01038ac:	ff d6                	call   *%esi
			putch('x', putdat);
f01038ae:	83 c4 08             	add    $0x8,%esp
f01038b1:	53                   	push   %ebx
f01038b2:	6a 78                	push   $0x78
f01038b4:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01038b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01038b9:	8d 50 04             	lea    0x4(%eax),%edx
f01038bc:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01038bf:	8b 00                	mov    (%eax),%eax
f01038c1:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01038c6:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01038c9:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01038ce:	eb 0d                	jmp    f01038dd <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01038d0:	8d 45 14             	lea    0x14(%ebp),%eax
f01038d3:	e8 3b fc ff ff       	call   f0103513 <getuint>
			base = 16;
f01038d8:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01038dd:	83 ec 0c             	sub    $0xc,%esp
f01038e0:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01038e4:	57                   	push   %edi
f01038e5:	ff 75 e0             	pushl  -0x20(%ebp)
f01038e8:	51                   	push   %ecx
f01038e9:	52                   	push   %edx
f01038ea:	50                   	push   %eax
f01038eb:	89 da                	mov    %ebx,%edx
f01038ed:	89 f0                	mov    %esi,%eax
f01038ef:	e8 70 fb ff ff       	call   f0103464 <printnum>
			break;
f01038f4:	83 c4 20             	add    $0x20,%esp
f01038f7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01038fa:	e9 ae fc ff ff       	jmp    f01035ad <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01038ff:	83 ec 08             	sub    $0x8,%esp
f0103902:	53                   	push   %ebx
f0103903:	51                   	push   %ecx
f0103904:	ff d6                	call   *%esi
			break;
f0103906:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103909:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010390c:	e9 9c fc ff ff       	jmp    f01035ad <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103911:	83 ec 08             	sub    $0x8,%esp
f0103914:	53                   	push   %ebx
f0103915:	6a 25                	push   $0x25
f0103917:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103919:	83 c4 10             	add    $0x10,%esp
f010391c:	eb 03                	jmp    f0103921 <vprintfmt+0x39a>
f010391e:	83 ef 01             	sub    $0x1,%edi
f0103921:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103925:	75 f7                	jne    f010391e <vprintfmt+0x397>
f0103927:	e9 81 fc ff ff       	jmp    f01035ad <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010392c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010392f:	5b                   	pop    %ebx
f0103930:	5e                   	pop    %esi
f0103931:	5f                   	pop    %edi
f0103932:	5d                   	pop    %ebp
f0103933:	c3                   	ret    

f0103934 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103934:	55                   	push   %ebp
f0103935:	89 e5                	mov    %esp,%ebp
f0103937:	83 ec 18             	sub    $0x18,%esp
f010393a:	8b 45 08             	mov    0x8(%ebp),%eax
f010393d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103940:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103943:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103947:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010394a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103951:	85 c0                	test   %eax,%eax
f0103953:	74 26                	je     f010397b <vsnprintf+0x47>
f0103955:	85 d2                	test   %edx,%edx
f0103957:	7e 22                	jle    f010397b <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103959:	ff 75 14             	pushl  0x14(%ebp)
f010395c:	ff 75 10             	pushl  0x10(%ebp)
f010395f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103962:	50                   	push   %eax
f0103963:	68 4d 35 10 f0       	push   $0xf010354d
f0103968:	e8 1a fc ff ff       	call   f0103587 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010396d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103970:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103973:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103976:	83 c4 10             	add    $0x10,%esp
f0103979:	eb 05                	jmp    f0103980 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010397b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103980:	c9                   	leave  
f0103981:	c3                   	ret    

f0103982 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103982:	55                   	push   %ebp
f0103983:	89 e5                	mov    %esp,%ebp
f0103985:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103988:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010398b:	50                   	push   %eax
f010398c:	ff 75 10             	pushl  0x10(%ebp)
f010398f:	ff 75 0c             	pushl  0xc(%ebp)
f0103992:	ff 75 08             	pushl  0x8(%ebp)
f0103995:	e8 9a ff ff ff       	call   f0103934 <vsnprintf>
	va_end(ap);

	return rc;
}
f010399a:	c9                   	leave  
f010399b:	c3                   	ret    

f010399c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010399c:	55                   	push   %ebp
f010399d:	89 e5                	mov    %esp,%ebp
f010399f:	57                   	push   %edi
f01039a0:	56                   	push   %esi
f01039a1:	53                   	push   %ebx
f01039a2:	83 ec 0c             	sub    $0xc,%esp
f01039a5:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01039a8:	85 c0                	test   %eax,%eax
f01039aa:	74 11                	je     f01039bd <readline+0x21>
		cprintf("%s", prompt);
f01039ac:	83 ec 08             	sub    $0x8,%esp
f01039af:	50                   	push   %eax
f01039b0:	68 e7 45 10 f0       	push   $0xf01045e7
f01039b5:	e8 62 f3 ff ff       	call   f0102d1c <cprintf>
f01039ba:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01039bd:	83 ec 0c             	sub    $0xc,%esp
f01039c0:	6a 00                	push   $0x0
f01039c2:	e8 61 cc ff ff       	call   f0100628 <iscons>
f01039c7:	89 c7                	mov    %eax,%edi
f01039c9:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01039cc:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01039d1:	e8 41 cc ff ff       	call   f0100617 <getchar>
f01039d6:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01039d8:	85 c0                	test   %eax,%eax
f01039da:	79 18                	jns    f01039f4 <readline+0x58>
			cprintf("read error: %e\n", c);
f01039dc:	83 ec 08             	sub    $0x8,%esp
f01039df:	50                   	push   %eax
f01039e0:	68 c0 56 10 f0       	push   $0xf01056c0
f01039e5:	e8 32 f3 ff ff       	call   f0102d1c <cprintf>
			return NULL;
f01039ea:	83 c4 10             	add    $0x10,%esp
f01039ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01039f2:	eb 79                	jmp    f0103a6d <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01039f4:	83 f8 08             	cmp    $0x8,%eax
f01039f7:	0f 94 c2             	sete   %dl
f01039fa:	83 f8 7f             	cmp    $0x7f,%eax
f01039fd:	0f 94 c0             	sete   %al
f0103a00:	08 c2                	or     %al,%dl
f0103a02:	74 1a                	je     f0103a1e <readline+0x82>
f0103a04:	85 f6                	test   %esi,%esi
f0103a06:	7e 16                	jle    f0103a1e <readline+0x82>
			if (echoing)
f0103a08:	85 ff                	test   %edi,%edi
f0103a0a:	74 0d                	je     f0103a19 <readline+0x7d>
				cputchar('\b');
f0103a0c:	83 ec 0c             	sub    $0xc,%esp
f0103a0f:	6a 08                	push   $0x8
f0103a11:	e8 f1 cb ff ff       	call   f0100607 <cputchar>
f0103a16:	83 c4 10             	add    $0x10,%esp
			i--;
f0103a19:	83 ee 01             	sub    $0x1,%esi
f0103a1c:	eb b3                	jmp    f01039d1 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103a1e:	83 fb 1f             	cmp    $0x1f,%ebx
f0103a21:	7e 23                	jle    f0103a46 <readline+0xaa>
f0103a23:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103a29:	7f 1b                	jg     f0103a46 <readline+0xaa>
			if (echoing)
f0103a2b:	85 ff                	test   %edi,%edi
f0103a2d:	74 0c                	je     f0103a3b <readline+0x9f>
				cputchar(c);
f0103a2f:	83 ec 0c             	sub    $0xc,%esp
f0103a32:	53                   	push   %ebx
f0103a33:	e8 cf cb ff ff       	call   f0100607 <cputchar>
f0103a38:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103a3b:	88 9e 00 4a 17 f0    	mov    %bl,-0xfe8b600(%esi)
f0103a41:	8d 76 01             	lea    0x1(%esi),%esi
f0103a44:	eb 8b                	jmp    f01039d1 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103a46:	83 fb 0a             	cmp    $0xa,%ebx
f0103a49:	74 05                	je     f0103a50 <readline+0xb4>
f0103a4b:	83 fb 0d             	cmp    $0xd,%ebx
f0103a4e:	75 81                	jne    f01039d1 <readline+0x35>
			if (echoing)
f0103a50:	85 ff                	test   %edi,%edi
f0103a52:	74 0d                	je     f0103a61 <readline+0xc5>
				cputchar('\n');
f0103a54:	83 ec 0c             	sub    $0xc,%esp
f0103a57:	6a 0a                	push   $0xa
f0103a59:	e8 a9 cb ff ff       	call   f0100607 <cputchar>
f0103a5e:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103a61:	c6 86 00 4a 17 f0 00 	movb   $0x0,-0xfe8b600(%esi)
			return buf;
f0103a68:	b8 00 4a 17 f0       	mov    $0xf0174a00,%eax
		}
	}
}
f0103a6d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a70:	5b                   	pop    %ebx
f0103a71:	5e                   	pop    %esi
f0103a72:	5f                   	pop    %edi
f0103a73:	5d                   	pop    %ebp
f0103a74:	c3                   	ret    

f0103a75 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103a75:	55                   	push   %ebp
f0103a76:	89 e5                	mov    %esp,%ebp
f0103a78:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a7b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a80:	eb 03                	jmp    f0103a85 <strlen+0x10>
		n++;
f0103a82:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a85:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103a89:	75 f7                	jne    f0103a82 <strlen+0xd>
		n++;
	return n;
}
f0103a8b:	5d                   	pop    %ebp
f0103a8c:	c3                   	ret    

f0103a8d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103a8d:	55                   	push   %ebp
f0103a8e:	89 e5                	mov    %esp,%ebp
f0103a90:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a93:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a96:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a9b:	eb 03                	jmp    f0103aa0 <strnlen+0x13>
		n++;
f0103a9d:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103aa0:	39 c2                	cmp    %eax,%edx
f0103aa2:	74 08                	je     f0103aac <strnlen+0x1f>
f0103aa4:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103aa8:	75 f3                	jne    f0103a9d <strnlen+0x10>
f0103aaa:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103aac:	5d                   	pop    %ebp
f0103aad:	c3                   	ret    

f0103aae <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103aae:	55                   	push   %ebp
f0103aaf:	89 e5                	mov    %esp,%ebp
f0103ab1:	53                   	push   %ebx
f0103ab2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ab5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103ab8:	89 c2                	mov    %eax,%edx
f0103aba:	83 c2 01             	add    $0x1,%edx
f0103abd:	83 c1 01             	add    $0x1,%ecx
f0103ac0:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103ac4:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103ac7:	84 db                	test   %bl,%bl
f0103ac9:	75 ef                	jne    f0103aba <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103acb:	5b                   	pop    %ebx
f0103acc:	5d                   	pop    %ebp
f0103acd:	c3                   	ret    

f0103ace <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103ace:	55                   	push   %ebp
f0103acf:	89 e5                	mov    %esp,%ebp
f0103ad1:	53                   	push   %ebx
f0103ad2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103ad5:	53                   	push   %ebx
f0103ad6:	e8 9a ff ff ff       	call   f0103a75 <strlen>
f0103adb:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103ade:	ff 75 0c             	pushl  0xc(%ebp)
f0103ae1:	01 d8                	add    %ebx,%eax
f0103ae3:	50                   	push   %eax
f0103ae4:	e8 c5 ff ff ff       	call   f0103aae <strcpy>
	return dst;
}
f0103ae9:	89 d8                	mov    %ebx,%eax
f0103aeb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103aee:	c9                   	leave  
f0103aef:	c3                   	ret    

f0103af0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103af0:	55                   	push   %ebp
f0103af1:	89 e5                	mov    %esp,%ebp
f0103af3:	56                   	push   %esi
f0103af4:	53                   	push   %ebx
f0103af5:	8b 75 08             	mov    0x8(%ebp),%esi
f0103af8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103afb:	89 f3                	mov    %esi,%ebx
f0103afd:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103b00:	89 f2                	mov    %esi,%edx
f0103b02:	eb 0f                	jmp    f0103b13 <strncpy+0x23>
		*dst++ = *src;
f0103b04:	83 c2 01             	add    $0x1,%edx
f0103b07:	0f b6 01             	movzbl (%ecx),%eax
f0103b0a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103b0d:	80 39 01             	cmpb   $0x1,(%ecx)
f0103b10:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103b13:	39 da                	cmp    %ebx,%edx
f0103b15:	75 ed                	jne    f0103b04 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103b17:	89 f0                	mov    %esi,%eax
f0103b19:	5b                   	pop    %ebx
f0103b1a:	5e                   	pop    %esi
f0103b1b:	5d                   	pop    %ebp
f0103b1c:	c3                   	ret    

f0103b1d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103b1d:	55                   	push   %ebp
f0103b1e:	89 e5                	mov    %esp,%ebp
f0103b20:	56                   	push   %esi
f0103b21:	53                   	push   %ebx
f0103b22:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b25:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103b28:	8b 55 10             	mov    0x10(%ebp),%edx
f0103b2b:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103b2d:	85 d2                	test   %edx,%edx
f0103b2f:	74 21                	je     f0103b52 <strlcpy+0x35>
f0103b31:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103b35:	89 f2                	mov    %esi,%edx
f0103b37:	eb 09                	jmp    f0103b42 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103b39:	83 c2 01             	add    $0x1,%edx
f0103b3c:	83 c1 01             	add    $0x1,%ecx
f0103b3f:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103b42:	39 c2                	cmp    %eax,%edx
f0103b44:	74 09                	je     f0103b4f <strlcpy+0x32>
f0103b46:	0f b6 19             	movzbl (%ecx),%ebx
f0103b49:	84 db                	test   %bl,%bl
f0103b4b:	75 ec                	jne    f0103b39 <strlcpy+0x1c>
f0103b4d:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103b4f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103b52:	29 f0                	sub    %esi,%eax
}
f0103b54:	5b                   	pop    %ebx
f0103b55:	5e                   	pop    %esi
f0103b56:	5d                   	pop    %ebp
f0103b57:	c3                   	ret    

f0103b58 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103b58:	55                   	push   %ebp
f0103b59:	89 e5                	mov    %esp,%ebp
f0103b5b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b5e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103b61:	eb 06                	jmp    f0103b69 <strcmp+0x11>
		p++, q++;
f0103b63:	83 c1 01             	add    $0x1,%ecx
f0103b66:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103b69:	0f b6 01             	movzbl (%ecx),%eax
f0103b6c:	84 c0                	test   %al,%al
f0103b6e:	74 04                	je     f0103b74 <strcmp+0x1c>
f0103b70:	3a 02                	cmp    (%edx),%al
f0103b72:	74 ef                	je     f0103b63 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b74:	0f b6 c0             	movzbl %al,%eax
f0103b77:	0f b6 12             	movzbl (%edx),%edx
f0103b7a:	29 d0                	sub    %edx,%eax
}
f0103b7c:	5d                   	pop    %ebp
f0103b7d:	c3                   	ret    

f0103b7e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103b7e:	55                   	push   %ebp
f0103b7f:	89 e5                	mov    %esp,%ebp
f0103b81:	53                   	push   %ebx
f0103b82:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b85:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b88:	89 c3                	mov    %eax,%ebx
f0103b8a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103b8d:	eb 06                	jmp    f0103b95 <strncmp+0x17>
		n--, p++, q++;
f0103b8f:	83 c0 01             	add    $0x1,%eax
f0103b92:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103b95:	39 d8                	cmp    %ebx,%eax
f0103b97:	74 15                	je     f0103bae <strncmp+0x30>
f0103b99:	0f b6 08             	movzbl (%eax),%ecx
f0103b9c:	84 c9                	test   %cl,%cl
f0103b9e:	74 04                	je     f0103ba4 <strncmp+0x26>
f0103ba0:	3a 0a                	cmp    (%edx),%cl
f0103ba2:	74 eb                	je     f0103b8f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103ba4:	0f b6 00             	movzbl (%eax),%eax
f0103ba7:	0f b6 12             	movzbl (%edx),%edx
f0103baa:	29 d0                	sub    %edx,%eax
f0103bac:	eb 05                	jmp    f0103bb3 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103bae:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103bb3:	5b                   	pop    %ebx
f0103bb4:	5d                   	pop    %ebp
f0103bb5:	c3                   	ret    

f0103bb6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103bb6:	55                   	push   %ebp
f0103bb7:	89 e5                	mov    %esp,%ebp
f0103bb9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bbc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103bc0:	eb 07                	jmp    f0103bc9 <strchr+0x13>
		if (*s == c)
f0103bc2:	38 ca                	cmp    %cl,%dl
f0103bc4:	74 0f                	je     f0103bd5 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103bc6:	83 c0 01             	add    $0x1,%eax
f0103bc9:	0f b6 10             	movzbl (%eax),%edx
f0103bcc:	84 d2                	test   %dl,%dl
f0103bce:	75 f2                	jne    f0103bc2 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103bd0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103bd5:	5d                   	pop    %ebp
f0103bd6:	c3                   	ret    

f0103bd7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103bd7:	55                   	push   %ebp
f0103bd8:	89 e5                	mov    %esp,%ebp
f0103bda:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bdd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103be1:	eb 03                	jmp    f0103be6 <strfind+0xf>
f0103be3:	83 c0 01             	add    $0x1,%eax
f0103be6:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103be9:	38 ca                	cmp    %cl,%dl
f0103beb:	74 04                	je     f0103bf1 <strfind+0x1a>
f0103bed:	84 d2                	test   %dl,%dl
f0103bef:	75 f2                	jne    f0103be3 <strfind+0xc>
			break;
	return (char *) s;
}
f0103bf1:	5d                   	pop    %ebp
f0103bf2:	c3                   	ret    

f0103bf3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103bf3:	55                   	push   %ebp
f0103bf4:	89 e5                	mov    %esp,%ebp
f0103bf6:	57                   	push   %edi
f0103bf7:	56                   	push   %esi
f0103bf8:	53                   	push   %ebx
f0103bf9:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103bfc:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103bff:	85 c9                	test   %ecx,%ecx
f0103c01:	74 36                	je     f0103c39 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103c03:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103c09:	75 28                	jne    f0103c33 <memset+0x40>
f0103c0b:	f6 c1 03             	test   $0x3,%cl
f0103c0e:	75 23                	jne    f0103c33 <memset+0x40>
		c &= 0xFF;
f0103c10:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103c14:	89 d3                	mov    %edx,%ebx
f0103c16:	c1 e3 08             	shl    $0x8,%ebx
f0103c19:	89 d6                	mov    %edx,%esi
f0103c1b:	c1 e6 18             	shl    $0x18,%esi
f0103c1e:	89 d0                	mov    %edx,%eax
f0103c20:	c1 e0 10             	shl    $0x10,%eax
f0103c23:	09 f0                	or     %esi,%eax
f0103c25:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103c27:	89 d8                	mov    %ebx,%eax
f0103c29:	09 d0                	or     %edx,%eax
f0103c2b:	c1 e9 02             	shr    $0x2,%ecx
f0103c2e:	fc                   	cld    
f0103c2f:	f3 ab                	rep stos %eax,%es:(%edi)
f0103c31:	eb 06                	jmp    f0103c39 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103c33:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c36:	fc                   	cld    
f0103c37:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103c39:	89 f8                	mov    %edi,%eax
f0103c3b:	5b                   	pop    %ebx
f0103c3c:	5e                   	pop    %esi
f0103c3d:	5f                   	pop    %edi
f0103c3e:	5d                   	pop    %ebp
f0103c3f:	c3                   	ret    

f0103c40 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103c40:	55                   	push   %ebp
f0103c41:	89 e5                	mov    %esp,%ebp
f0103c43:	57                   	push   %edi
f0103c44:	56                   	push   %esi
f0103c45:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c48:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c4b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103c4e:	39 c6                	cmp    %eax,%esi
f0103c50:	73 35                	jae    f0103c87 <memmove+0x47>
f0103c52:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103c55:	39 d0                	cmp    %edx,%eax
f0103c57:	73 2e                	jae    f0103c87 <memmove+0x47>
		s += n;
		d += n;
f0103c59:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c5c:	89 d6                	mov    %edx,%esi
f0103c5e:	09 fe                	or     %edi,%esi
f0103c60:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103c66:	75 13                	jne    f0103c7b <memmove+0x3b>
f0103c68:	f6 c1 03             	test   $0x3,%cl
f0103c6b:	75 0e                	jne    f0103c7b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103c6d:	83 ef 04             	sub    $0x4,%edi
f0103c70:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103c73:	c1 e9 02             	shr    $0x2,%ecx
f0103c76:	fd                   	std    
f0103c77:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c79:	eb 09                	jmp    f0103c84 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103c7b:	83 ef 01             	sub    $0x1,%edi
f0103c7e:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103c81:	fd                   	std    
f0103c82:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103c84:	fc                   	cld    
f0103c85:	eb 1d                	jmp    f0103ca4 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c87:	89 f2                	mov    %esi,%edx
f0103c89:	09 c2                	or     %eax,%edx
f0103c8b:	f6 c2 03             	test   $0x3,%dl
f0103c8e:	75 0f                	jne    f0103c9f <memmove+0x5f>
f0103c90:	f6 c1 03             	test   $0x3,%cl
f0103c93:	75 0a                	jne    f0103c9f <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103c95:	c1 e9 02             	shr    $0x2,%ecx
f0103c98:	89 c7                	mov    %eax,%edi
f0103c9a:	fc                   	cld    
f0103c9b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c9d:	eb 05                	jmp    f0103ca4 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103c9f:	89 c7                	mov    %eax,%edi
f0103ca1:	fc                   	cld    
f0103ca2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103ca4:	5e                   	pop    %esi
f0103ca5:	5f                   	pop    %edi
f0103ca6:	5d                   	pop    %ebp
f0103ca7:	c3                   	ret    

f0103ca8 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103ca8:	55                   	push   %ebp
f0103ca9:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103cab:	ff 75 10             	pushl  0x10(%ebp)
f0103cae:	ff 75 0c             	pushl  0xc(%ebp)
f0103cb1:	ff 75 08             	pushl  0x8(%ebp)
f0103cb4:	e8 87 ff ff ff       	call   f0103c40 <memmove>
}
f0103cb9:	c9                   	leave  
f0103cba:	c3                   	ret    

f0103cbb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103cbb:	55                   	push   %ebp
f0103cbc:	89 e5                	mov    %esp,%ebp
f0103cbe:	56                   	push   %esi
f0103cbf:	53                   	push   %ebx
f0103cc0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cc3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103cc6:	89 c6                	mov    %eax,%esi
f0103cc8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103ccb:	eb 1a                	jmp    f0103ce7 <memcmp+0x2c>
		if (*s1 != *s2)
f0103ccd:	0f b6 08             	movzbl (%eax),%ecx
f0103cd0:	0f b6 1a             	movzbl (%edx),%ebx
f0103cd3:	38 d9                	cmp    %bl,%cl
f0103cd5:	74 0a                	je     f0103ce1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103cd7:	0f b6 c1             	movzbl %cl,%eax
f0103cda:	0f b6 db             	movzbl %bl,%ebx
f0103cdd:	29 d8                	sub    %ebx,%eax
f0103cdf:	eb 0f                	jmp    f0103cf0 <memcmp+0x35>
		s1++, s2++;
f0103ce1:	83 c0 01             	add    $0x1,%eax
f0103ce4:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103ce7:	39 f0                	cmp    %esi,%eax
f0103ce9:	75 e2                	jne    f0103ccd <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103ceb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103cf0:	5b                   	pop    %ebx
f0103cf1:	5e                   	pop    %esi
f0103cf2:	5d                   	pop    %ebp
f0103cf3:	c3                   	ret    

f0103cf4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103cf4:	55                   	push   %ebp
f0103cf5:	89 e5                	mov    %esp,%ebp
f0103cf7:	53                   	push   %ebx
f0103cf8:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103cfb:	89 c1                	mov    %eax,%ecx
f0103cfd:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d00:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103d04:	eb 0a                	jmp    f0103d10 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d06:	0f b6 10             	movzbl (%eax),%edx
f0103d09:	39 da                	cmp    %ebx,%edx
f0103d0b:	74 07                	je     f0103d14 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103d0d:	83 c0 01             	add    $0x1,%eax
f0103d10:	39 c8                	cmp    %ecx,%eax
f0103d12:	72 f2                	jb     f0103d06 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103d14:	5b                   	pop    %ebx
f0103d15:	5d                   	pop    %ebp
f0103d16:	c3                   	ret    

f0103d17 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103d17:	55                   	push   %ebp
f0103d18:	89 e5                	mov    %esp,%ebp
f0103d1a:	57                   	push   %edi
f0103d1b:	56                   	push   %esi
f0103d1c:	53                   	push   %ebx
f0103d1d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103d20:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d23:	eb 03                	jmp    f0103d28 <strtol+0x11>
		s++;
f0103d25:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d28:	0f b6 01             	movzbl (%ecx),%eax
f0103d2b:	3c 20                	cmp    $0x20,%al
f0103d2d:	74 f6                	je     f0103d25 <strtol+0xe>
f0103d2f:	3c 09                	cmp    $0x9,%al
f0103d31:	74 f2                	je     f0103d25 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103d33:	3c 2b                	cmp    $0x2b,%al
f0103d35:	75 0a                	jne    f0103d41 <strtol+0x2a>
		s++;
f0103d37:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103d3a:	bf 00 00 00 00       	mov    $0x0,%edi
f0103d3f:	eb 11                	jmp    f0103d52 <strtol+0x3b>
f0103d41:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103d46:	3c 2d                	cmp    $0x2d,%al
f0103d48:	75 08                	jne    f0103d52 <strtol+0x3b>
		s++, neg = 1;
f0103d4a:	83 c1 01             	add    $0x1,%ecx
f0103d4d:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d52:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103d58:	75 15                	jne    f0103d6f <strtol+0x58>
f0103d5a:	80 39 30             	cmpb   $0x30,(%ecx)
f0103d5d:	75 10                	jne    f0103d6f <strtol+0x58>
f0103d5f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103d63:	75 7c                	jne    f0103de1 <strtol+0xca>
		s += 2, base = 16;
f0103d65:	83 c1 02             	add    $0x2,%ecx
f0103d68:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103d6d:	eb 16                	jmp    f0103d85 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103d6f:	85 db                	test   %ebx,%ebx
f0103d71:	75 12                	jne    f0103d85 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103d73:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103d78:	80 39 30             	cmpb   $0x30,(%ecx)
f0103d7b:	75 08                	jne    f0103d85 <strtol+0x6e>
		s++, base = 8;
f0103d7d:	83 c1 01             	add    $0x1,%ecx
f0103d80:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103d85:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d8a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103d8d:	0f b6 11             	movzbl (%ecx),%edx
f0103d90:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103d93:	89 f3                	mov    %esi,%ebx
f0103d95:	80 fb 09             	cmp    $0x9,%bl
f0103d98:	77 08                	ja     f0103da2 <strtol+0x8b>
			dig = *s - '0';
f0103d9a:	0f be d2             	movsbl %dl,%edx
f0103d9d:	83 ea 30             	sub    $0x30,%edx
f0103da0:	eb 22                	jmp    f0103dc4 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103da2:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103da5:	89 f3                	mov    %esi,%ebx
f0103da7:	80 fb 19             	cmp    $0x19,%bl
f0103daa:	77 08                	ja     f0103db4 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103dac:	0f be d2             	movsbl %dl,%edx
f0103daf:	83 ea 57             	sub    $0x57,%edx
f0103db2:	eb 10                	jmp    f0103dc4 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103db4:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103db7:	89 f3                	mov    %esi,%ebx
f0103db9:	80 fb 19             	cmp    $0x19,%bl
f0103dbc:	77 16                	ja     f0103dd4 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103dbe:	0f be d2             	movsbl %dl,%edx
f0103dc1:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103dc4:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103dc7:	7d 0b                	jge    f0103dd4 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103dc9:	83 c1 01             	add    $0x1,%ecx
f0103dcc:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103dd0:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103dd2:	eb b9                	jmp    f0103d8d <strtol+0x76>

	if (endptr)
f0103dd4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103dd8:	74 0d                	je     f0103de7 <strtol+0xd0>
		*endptr = (char *) s;
f0103dda:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ddd:	89 0e                	mov    %ecx,(%esi)
f0103ddf:	eb 06                	jmp    f0103de7 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103de1:	85 db                	test   %ebx,%ebx
f0103de3:	74 98                	je     f0103d7d <strtol+0x66>
f0103de5:	eb 9e                	jmp    f0103d85 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103de7:	89 c2                	mov    %eax,%edx
f0103de9:	f7 da                	neg    %edx
f0103deb:	85 ff                	test   %edi,%edi
f0103ded:	0f 45 c2             	cmovne %edx,%eax
}
f0103df0:	5b                   	pop    %ebx
f0103df1:	5e                   	pop    %esi
f0103df2:	5f                   	pop    %edi
f0103df3:	5d                   	pop    %ebp
f0103df4:	c3                   	ret    
f0103df5:	66 90                	xchg   %ax,%ax
f0103df7:	66 90                	xchg   %ax,%ax
f0103df9:	66 90                	xchg   %ax,%ax
f0103dfb:	66 90                	xchg   %ax,%ax
f0103dfd:	66 90                	xchg   %ax,%ax
f0103dff:	90                   	nop

f0103e00 <__udivdi3>:
f0103e00:	55                   	push   %ebp
f0103e01:	57                   	push   %edi
f0103e02:	56                   	push   %esi
f0103e03:	53                   	push   %ebx
f0103e04:	83 ec 1c             	sub    $0x1c,%esp
f0103e07:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0103e0b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0103e0f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103e13:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103e17:	85 f6                	test   %esi,%esi
f0103e19:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103e1d:	89 ca                	mov    %ecx,%edx
f0103e1f:	89 f8                	mov    %edi,%eax
f0103e21:	75 3d                	jne    f0103e60 <__udivdi3+0x60>
f0103e23:	39 cf                	cmp    %ecx,%edi
f0103e25:	0f 87 c5 00 00 00    	ja     f0103ef0 <__udivdi3+0xf0>
f0103e2b:	85 ff                	test   %edi,%edi
f0103e2d:	89 fd                	mov    %edi,%ebp
f0103e2f:	75 0b                	jne    f0103e3c <__udivdi3+0x3c>
f0103e31:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e36:	31 d2                	xor    %edx,%edx
f0103e38:	f7 f7                	div    %edi
f0103e3a:	89 c5                	mov    %eax,%ebp
f0103e3c:	89 c8                	mov    %ecx,%eax
f0103e3e:	31 d2                	xor    %edx,%edx
f0103e40:	f7 f5                	div    %ebp
f0103e42:	89 c1                	mov    %eax,%ecx
f0103e44:	89 d8                	mov    %ebx,%eax
f0103e46:	89 cf                	mov    %ecx,%edi
f0103e48:	f7 f5                	div    %ebp
f0103e4a:	89 c3                	mov    %eax,%ebx
f0103e4c:	89 d8                	mov    %ebx,%eax
f0103e4e:	89 fa                	mov    %edi,%edx
f0103e50:	83 c4 1c             	add    $0x1c,%esp
f0103e53:	5b                   	pop    %ebx
f0103e54:	5e                   	pop    %esi
f0103e55:	5f                   	pop    %edi
f0103e56:	5d                   	pop    %ebp
f0103e57:	c3                   	ret    
f0103e58:	90                   	nop
f0103e59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e60:	39 ce                	cmp    %ecx,%esi
f0103e62:	77 74                	ja     f0103ed8 <__udivdi3+0xd8>
f0103e64:	0f bd fe             	bsr    %esi,%edi
f0103e67:	83 f7 1f             	xor    $0x1f,%edi
f0103e6a:	0f 84 98 00 00 00    	je     f0103f08 <__udivdi3+0x108>
f0103e70:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103e75:	89 f9                	mov    %edi,%ecx
f0103e77:	89 c5                	mov    %eax,%ebp
f0103e79:	29 fb                	sub    %edi,%ebx
f0103e7b:	d3 e6                	shl    %cl,%esi
f0103e7d:	89 d9                	mov    %ebx,%ecx
f0103e7f:	d3 ed                	shr    %cl,%ebp
f0103e81:	89 f9                	mov    %edi,%ecx
f0103e83:	d3 e0                	shl    %cl,%eax
f0103e85:	09 ee                	or     %ebp,%esi
f0103e87:	89 d9                	mov    %ebx,%ecx
f0103e89:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e8d:	89 d5                	mov    %edx,%ebp
f0103e8f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103e93:	d3 ed                	shr    %cl,%ebp
f0103e95:	89 f9                	mov    %edi,%ecx
f0103e97:	d3 e2                	shl    %cl,%edx
f0103e99:	89 d9                	mov    %ebx,%ecx
f0103e9b:	d3 e8                	shr    %cl,%eax
f0103e9d:	09 c2                	or     %eax,%edx
f0103e9f:	89 d0                	mov    %edx,%eax
f0103ea1:	89 ea                	mov    %ebp,%edx
f0103ea3:	f7 f6                	div    %esi
f0103ea5:	89 d5                	mov    %edx,%ebp
f0103ea7:	89 c3                	mov    %eax,%ebx
f0103ea9:	f7 64 24 0c          	mull   0xc(%esp)
f0103ead:	39 d5                	cmp    %edx,%ebp
f0103eaf:	72 10                	jb     f0103ec1 <__udivdi3+0xc1>
f0103eb1:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103eb5:	89 f9                	mov    %edi,%ecx
f0103eb7:	d3 e6                	shl    %cl,%esi
f0103eb9:	39 c6                	cmp    %eax,%esi
f0103ebb:	73 07                	jae    f0103ec4 <__udivdi3+0xc4>
f0103ebd:	39 d5                	cmp    %edx,%ebp
f0103ebf:	75 03                	jne    f0103ec4 <__udivdi3+0xc4>
f0103ec1:	83 eb 01             	sub    $0x1,%ebx
f0103ec4:	31 ff                	xor    %edi,%edi
f0103ec6:	89 d8                	mov    %ebx,%eax
f0103ec8:	89 fa                	mov    %edi,%edx
f0103eca:	83 c4 1c             	add    $0x1c,%esp
f0103ecd:	5b                   	pop    %ebx
f0103ece:	5e                   	pop    %esi
f0103ecf:	5f                   	pop    %edi
f0103ed0:	5d                   	pop    %ebp
f0103ed1:	c3                   	ret    
f0103ed2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ed8:	31 ff                	xor    %edi,%edi
f0103eda:	31 db                	xor    %ebx,%ebx
f0103edc:	89 d8                	mov    %ebx,%eax
f0103ede:	89 fa                	mov    %edi,%edx
f0103ee0:	83 c4 1c             	add    $0x1c,%esp
f0103ee3:	5b                   	pop    %ebx
f0103ee4:	5e                   	pop    %esi
f0103ee5:	5f                   	pop    %edi
f0103ee6:	5d                   	pop    %ebp
f0103ee7:	c3                   	ret    
f0103ee8:	90                   	nop
f0103ee9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103ef0:	89 d8                	mov    %ebx,%eax
f0103ef2:	f7 f7                	div    %edi
f0103ef4:	31 ff                	xor    %edi,%edi
f0103ef6:	89 c3                	mov    %eax,%ebx
f0103ef8:	89 d8                	mov    %ebx,%eax
f0103efa:	89 fa                	mov    %edi,%edx
f0103efc:	83 c4 1c             	add    $0x1c,%esp
f0103eff:	5b                   	pop    %ebx
f0103f00:	5e                   	pop    %esi
f0103f01:	5f                   	pop    %edi
f0103f02:	5d                   	pop    %ebp
f0103f03:	c3                   	ret    
f0103f04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f08:	39 ce                	cmp    %ecx,%esi
f0103f0a:	72 0c                	jb     f0103f18 <__udivdi3+0x118>
f0103f0c:	31 db                	xor    %ebx,%ebx
f0103f0e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103f12:	0f 87 34 ff ff ff    	ja     f0103e4c <__udivdi3+0x4c>
f0103f18:	bb 01 00 00 00       	mov    $0x1,%ebx
f0103f1d:	e9 2a ff ff ff       	jmp    f0103e4c <__udivdi3+0x4c>
f0103f22:	66 90                	xchg   %ax,%ax
f0103f24:	66 90                	xchg   %ax,%ax
f0103f26:	66 90                	xchg   %ax,%ax
f0103f28:	66 90                	xchg   %ax,%ax
f0103f2a:	66 90                	xchg   %ax,%ax
f0103f2c:	66 90                	xchg   %ax,%ax
f0103f2e:	66 90                	xchg   %ax,%ax

f0103f30 <__umoddi3>:
f0103f30:	55                   	push   %ebp
f0103f31:	57                   	push   %edi
f0103f32:	56                   	push   %esi
f0103f33:	53                   	push   %ebx
f0103f34:	83 ec 1c             	sub    $0x1c,%esp
f0103f37:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103f3b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103f3f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103f43:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103f47:	85 d2                	test   %edx,%edx
f0103f49:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103f4d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103f51:	89 f3                	mov    %esi,%ebx
f0103f53:	89 3c 24             	mov    %edi,(%esp)
f0103f56:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103f5a:	75 1c                	jne    f0103f78 <__umoddi3+0x48>
f0103f5c:	39 f7                	cmp    %esi,%edi
f0103f5e:	76 50                	jbe    f0103fb0 <__umoddi3+0x80>
f0103f60:	89 c8                	mov    %ecx,%eax
f0103f62:	89 f2                	mov    %esi,%edx
f0103f64:	f7 f7                	div    %edi
f0103f66:	89 d0                	mov    %edx,%eax
f0103f68:	31 d2                	xor    %edx,%edx
f0103f6a:	83 c4 1c             	add    $0x1c,%esp
f0103f6d:	5b                   	pop    %ebx
f0103f6e:	5e                   	pop    %esi
f0103f6f:	5f                   	pop    %edi
f0103f70:	5d                   	pop    %ebp
f0103f71:	c3                   	ret    
f0103f72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103f78:	39 f2                	cmp    %esi,%edx
f0103f7a:	89 d0                	mov    %edx,%eax
f0103f7c:	77 52                	ja     f0103fd0 <__umoddi3+0xa0>
f0103f7e:	0f bd ea             	bsr    %edx,%ebp
f0103f81:	83 f5 1f             	xor    $0x1f,%ebp
f0103f84:	75 5a                	jne    f0103fe0 <__umoddi3+0xb0>
f0103f86:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0103f8a:	0f 82 e0 00 00 00    	jb     f0104070 <__umoddi3+0x140>
f0103f90:	39 0c 24             	cmp    %ecx,(%esp)
f0103f93:	0f 86 d7 00 00 00    	jbe    f0104070 <__umoddi3+0x140>
f0103f99:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103f9d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103fa1:	83 c4 1c             	add    $0x1c,%esp
f0103fa4:	5b                   	pop    %ebx
f0103fa5:	5e                   	pop    %esi
f0103fa6:	5f                   	pop    %edi
f0103fa7:	5d                   	pop    %ebp
f0103fa8:	c3                   	ret    
f0103fa9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103fb0:	85 ff                	test   %edi,%edi
f0103fb2:	89 fd                	mov    %edi,%ebp
f0103fb4:	75 0b                	jne    f0103fc1 <__umoddi3+0x91>
f0103fb6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103fbb:	31 d2                	xor    %edx,%edx
f0103fbd:	f7 f7                	div    %edi
f0103fbf:	89 c5                	mov    %eax,%ebp
f0103fc1:	89 f0                	mov    %esi,%eax
f0103fc3:	31 d2                	xor    %edx,%edx
f0103fc5:	f7 f5                	div    %ebp
f0103fc7:	89 c8                	mov    %ecx,%eax
f0103fc9:	f7 f5                	div    %ebp
f0103fcb:	89 d0                	mov    %edx,%eax
f0103fcd:	eb 99                	jmp    f0103f68 <__umoddi3+0x38>
f0103fcf:	90                   	nop
f0103fd0:	89 c8                	mov    %ecx,%eax
f0103fd2:	89 f2                	mov    %esi,%edx
f0103fd4:	83 c4 1c             	add    $0x1c,%esp
f0103fd7:	5b                   	pop    %ebx
f0103fd8:	5e                   	pop    %esi
f0103fd9:	5f                   	pop    %edi
f0103fda:	5d                   	pop    %ebp
f0103fdb:	c3                   	ret    
f0103fdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103fe0:	8b 34 24             	mov    (%esp),%esi
f0103fe3:	bf 20 00 00 00       	mov    $0x20,%edi
f0103fe8:	89 e9                	mov    %ebp,%ecx
f0103fea:	29 ef                	sub    %ebp,%edi
f0103fec:	d3 e0                	shl    %cl,%eax
f0103fee:	89 f9                	mov    %edi,%ecx
f0103ff0:	89 f2                	mov    %esi,%edx
f0103ff2:	d3 ea                	shr    %cl,%edx
f0103ff4:	89 e9                	mov    %ebp,%ecx
f0103ff6:	09 c2                	or     %eax,%edx
f0103ff8:	89 d8                	mov    %ebx,%eax
f0103ffa:	89 14 24             	mov    %edx,(%esp)
f0103ffd:	89 f2                	mov    %esi,%edx
f0103fff:	d3 e2                	shl    %cl,%edx
f0104001:	89 f9                	mov    %edi,%ecx
f0104003:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104007:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010400b:	d3 e8                	shr    %cl,%eax
f010400d:	89 e9                	mov    %ebp,%ecx
f010400f:	89 c6                	mov    %eax,%esi
f0104011:	d3 e3                	shl    %cl,%ebx
f0104013:	89 f9                	mov    %edi,%ecx
f0104015:	89 d0                	mov    %edx,%eax
f0104017:	d3 e8                	shr    %cl,%eax
f0104019:	89 e9                	mov    %ebp,%ecx
f010401b:	09 d8                	or     %ebx,%eax
f010401d:	89 d3                	mov    %edx,%ebx
f010401f:	89 f2                	mov    %esi,%edx
f0104021:	f7 34 24             	divl   (%esp)
f0104024:	89 d6                	mov    %edx,%esi
f0104026:	d3 e3                	shl    %cl,%ebx
f0104028:	f7 64 24 04          	mull   0x4(%esp)
f010402c:	39 d6                	cmp    %edx,%esi
f010402e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104032:	89 d1                	mov    %edx,%ecx
f0104034:	89 c3                	mov    %eax,%ebx
f0104036:	72 08                	jb     f0104040 <__umoddi3+0x110>
f0104038:	75 11                	jne    f010404b <__umoddi3+0x11b>
f010403a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010403e:	73 0b                	jae    f010404b <__umoddi3+0x11b>
f0104040:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104044:	1b 14 24             	sbb    (%esp),%edx
f0104047:	89 d1                	mov    %edx,%ecx
f0104049:	89 c3                	mov    %eax,%ebx
f010404b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010404f:	29 da                	sub    %ebx,%edx
f0104051:	19 ce                	sbb    %ecx,%esi
f0104053:	89 f9                	mov    %edi,%ecx
f0104055:	89 f0                	mov    %esi,%eax
f0104057:	d3 e0                	shl    %cl,%eax
f0104059:	89 e9                	mov    %ebp,%ecx
f010405b:	d3 ea                	shr    %cl,%edx
f010405d:	89 e9                	mov    %ebp,%ecx
f010405f:	d3 ee                	shr    %cl,%esi
f0104061:	09 d0                	or     %edx,%eax
f0104063:	89 f2                	mov    %esi,%edx
f0104065:	83 c4 1c             	add    $0x1c,%esp
f0104068:	5b                   	pop    %ebx
f0104069:	5e                   	pop    %esi
f010406a:	5f                   	pop    %edi
f010406b:	5d                   	pop    %ebp
f010406c:	c3                   	ret    
f010406d:	8d 76 00             	lea    0x0(%esi),%esi
f0104070:	29 f9                	sub    %edi,%ecx
f0104072:	19 d6                	sbb    %edx,%esi
f0104074:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104078:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010407c:	e9 18 ff ff ff       	jmp    f0103f99 <__umoddi3+0x69>
