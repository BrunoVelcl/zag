# Zag

## Important 
Builds with Zig 13.0

### About
Zag is a small Zig CLI development helper tool. The tool is meant to be added in the system path for convinience but can be used without it with some limitations.  For buit in help menu just type zag, or for help with a specific tool zag -h <tool>.

---

### Tools
##### **init, initexe**     
Usage: zag init [name]

Creates a new empty Zig executable project with minimal boilerplatze or comments.

Behavior:
    - If no name is provided, the project is initialized in the current directory.
    - If a name is provided, a new directory with that name is created, and the project is set up inside it.

##### **initlib** 
Usage: zag init [name]

Same behavior as init but for making non executable projects like librarries.

##### **time**
Usage: zag time [options] <program to test> [program's options]

Measures a program's execution speed. Usefull for quick benchmarks, relative comparisons and making sure theres no huge bottlenecks in a program your testinng. Note that it doesn't stop timing on child program "pause" events. Only relevant measurements can be done on programs that execute without user input.

Options:
    -i n   Set the number of times (n) you want to test the program.
    -q     "quiet" - Prevents the child program from outputting to the console.

##### hex
Usage: zag hex [options] "Optional input"

This tool is useful when debugging, it will convert hexadecimal values into its ASCII character.

Modes:
    1. Input mode: If you provide hexadecimal values inside quotation marks, the program will decipher them and combine the resulting characters.
        2. Console mode: Without direct input, the program will decipher the hex values currently displayed in your console window and replace them in place.

Options:
    -w  Use this option to decipher 16-bit clusters (e.g., "4865 6c6c 6f20 576f 726c 6421"). By default, the program deciphers 8-bit clusters (e.g., "48 65 6c 6c 6f 20 57 6f 72 6c 64 21").

##### int

Usage: zag int [options] "Optional input"

Same idea as the hex tool but for converting integers into ASCII characters.

Modes:
    1. Input mode: If you provide integer values inside quotation marks, the program will decipher them and combine the resulting characters.
    2. Console mode: Without direct input, the program will decipher the integer values from your console window and replace them in place.
