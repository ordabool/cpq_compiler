# Compilation Project

- Currently, the main challenge is to compile flex & bison together, and build a stable environment that I can test and iterate over, instead of running blindly
- Also, all of my notes are inside the src like a common fool - use Obsidian to organize what needs to be done
- Use source control! After building the initial stable env, start tracking changes and progress with git
- Review the assignment PDF again, and try to break it into steps that will be tasks in this note. Then, it will be much easier to understand what needs to be done
- Overall - break the project into small understandable tasks, just like at work, code in an organized fashion, and this thing will progress much faster

---

כשירות לציבור, מי שמשתמש בBISON וצריך שזה לא יפסיק כשזה פוגש error ראשון, שישתמש בדקדוק הזה.

רק תקראו בchatgpt או משהו על הוספת yyerrok ו-yyclearin (צריך לכל כלל גזירה של errors) 
וגם על פונקצית yyerror

---

See makefile example at: https://github.com/ordabool/ex1_matam/blob/main/submission/makefile

---

## TODOs:

- [x] Go over the requirements file and break everything into tasks
- [x] Build the skeleton for the lexical analyzer using flex
- [x] Build the skeleton for the parser using bison
- [x] Build the skeleton for the main function inside `cpq.c`
- [x] Compile all files together into a unified `cpq.exe` file (in WSL disregard the `exe`) - preferably using a `makefile`
- [x] Start using git for source control
- [x] Test the simplest version of the parser and lexer using the executable file - **continue development only after this step!**
- [x] Make the lexer ignore comments
- [x] Fix the bug where `make` overwrites `cpq.c` file - happens when modifying cpq.y and running make
- [x] Understand how to pass `yylval` from flex to bison, with the right type
- [x] Try to export TODOs from the source files into this note, to better manage all the requirements
- [ ] Use linked list for the generated QUAD lines, and have a pointer to the end of the list
- [ ] Use a hash table for the symbols table - not a linked list!
- [ ] Make sure the output file for submission is a windows executable (`exe`)
- [ ] Accept input files only with the `.ou` extension
- [ ] Name the generated file the same as the input, but with a `.qud` extension
- [ ] Add a "Signature line" (my name) into the standard error channel, and also as a last line after the final `HALT` command in the generated code 
- [ ] When spotting an error, record it in the standard error channel with the causing line number, and **DON'T** generate the `.qud` file
- [ ] Don't stop the execution after an error - try to continue the parsing process as much as possible to catch more errors
- [ ] Don't create an AST, instead generate the Quad code during the syntax analysis (the parser's runtime)
- [ ] Hold the generated code in memory (no need to dump into temp files), and reiterate over it to replace labels with line numbers (backpatching is more efficient, but harder to do)
- [ ] Create an efficient implementation for the symbols table - probably a hash table (wrote specifically not to use linked lists)
- [ ] Same with the quad code - make sure that the object holding it has an option to jump to the end at O(1), because it will happen a lot throughout the process
- [ ] Make sure the code is well documented using comments where needed - but don't overdo it with comments
- [ ] Write a document (1-2 pages) that specifies the implementation I've chosen, and the overall structure of the compiler. Explain why I've chosen anything that I chose
- [ ] In the submission, include a `src` folder (holding all of the source files), `cpq.exe`, `README` - explain how to build, `makefile`, and the additional doc PDF
- [ ] Test the output on the provided Quad interpreter - make sure to tests cases with error as well
- [ ] Lexer comments - see why printing newlines when having block comments with newline, and check that the "start condition" implementation is correct
- [ ] Run a prettifier on all code to make sure no stupid tabs/spaces remains and looks like copied code
- [ ] Go over previous assignments before submitting - maybe he told me how to improve something


TODOs from code:
- [ ] Generate lexer strictly / verbose - to solve problems like I had in first HW (ignored unrecognized by default) - Use something like: flex q2.lex && gcc -DECHO lex.yy.c -o cla && ./cla ./code.ou
- [ ] Check if need to import atoi and other similar funcs
- [ ] Check if a space between cast and '<' allowed


---

היי גדי, אור מקורס קומפילציה

לגבי פרויקט הסיום של הקורס - המבחן כבר מאחורינו, אבל אני נמצא בתקופה די משוגעת כי אני מתחתן ממש בקרוב (יחד עם סמסטר חדש), ואין לי כמעט זמן לעבוד על הפרויקט כמו שצריך. אני עובד עליו כבר הרבה זמן, אבל נשארה הרבה עבודה. רציתי לשאול אם יש אפשרות לקבל דחייה בהגשה או אם יש פיתרון אחר כלשהו.

אני מבין שזה חריג, אבל אם יש איזושהי גמישות במקרה כזה – זה ממש יעזור לי. תודה מראש על ההתחשבות!