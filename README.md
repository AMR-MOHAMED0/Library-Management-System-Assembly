# Library Management System (x86 Assembly)

## Project Overview

This repository hosts a robust and fully functional **Library Management System** implemented entirely in **x86 Assembly Language**. Developed as a final project for the Computer Science curriculum at Mansoura University, this system demonstrates a deep understanding of low-level programming, memory management, and direct hardware interaction via interrupts.

The application provides core functionalities for managing a library's inventory, including adding, viewing, searching, and deleting book records.

## Technical Depth and Implementation Highlights

The project was engineered to showcase advanced assembly programming techniques, including:

- **Parallel Arrays for Data Structuring:** Book records are managed efficiently using multiple parallel arrays. This technique allows for fast lookups and manipulation of related data fields (e.g., Book Title, Author, ISBN, Quantity) while maintaining the low-level control inherent to assembly.
- **BIOS and DOS Interrupts:** Extensive use of **INT 21h** (DOS services) and **INT 10h** (Video services) for screen manipulation, keyboard input, and file I/O operations, ensuring direct and efficient interaction with the operating system environment.
- **Input Validation and Error Handling:** Robust routines are implemented to validate user input (e.g., ensuring numeric fields contain only digits, checking string lengths) to prevent system crashes and maintain data integrity.
- **Modular Design:** The codebase is structured into clearly defined procedures and subroutines, promoting readability and maintainability—a critical practice even in assembly language programming.

## How to Run the Project

This project is designed to be compiled and executed within the **EMU8086** emulator environment.

1.  **Prerequisites:** Ensure you have the EMU8086 emulator installed on your system.
2.  **Open Source File:** Open the main source file, `Assembly Final Project.asm`, directly within the EMU8086 application.
3.  **Compile and Run:** Use the built-in "Compile" and "Run" functionalities within EMU8086. The program will execute in a simulated DOS environment.

## Video Demonstration

A full video demonstration of the system's functionality is available. This video walks through the user interface, data entry, search features, and error handling.

[**Link to Video Demonstration**](https://drive.google.com/file/d/1s0bD_sVqI5_6bKXNBRMei2ybQQ0JABGS/view?usp=drive_link)

---

## Author

**Amr Mohamed Mahmoud**

- FCIS, Computer Science Student, Year 3
- Mansoura University

## License

This project is open-source and available under the MIT License. (Consider adding a LICENSE file for completeness.)
