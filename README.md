*This project has been created as part of the 42 curriculum by alebarbo, lseabra-.*

# Minishell

## Description
**Minishell** is a project designed to recreate a simple command-line shell similar to Bash. The objective is to gain extensive knowledge about processes, file descriptors, and the inner workings of a Unix shell, from reading user input to executing programs.

The shell reads and executes commands in an interactive loop, supporting a prompt with history, quoting rules, environment variable expansion, redirections, pipes, logical operators, subshells, and all the standard built-in commands. It handles signals in a Bash-compatible way and maintains a clean separation between the main process and forked child processes.

The bonus part adds support for `&&` and `||` logical operators with parenthesized grouping for priority, as well as wildcard (`*`) expansion in the current working directory.

## Instructions
**Installation**
* Run `make` on the root folder of the project to compile `minishell`.
* Run `make bonus` on the root folder of the project to also compile the bonus version.

**Execution**
* Run `./minishell` to start the interactive shell.

```
$> ./minishell
minishell$ echo "Hello, World!"
Hello, World!
minishell$ ls | grep .c | wc -l
42
minishell$ VAR=hello; echo $VAR
hello
minishell$ exit
```

In case of a syntax error, the shell displays `Syntax error` on the standard error and waits for the next command without exiting.

**Built-in commands**

| Command | Description |
|---|---|
| `echo [-n]` | Print text to standard output; `-n` suppresses the trailing newline |
| `cd [path]` | Change the current directory using a relative or absolute path |
| `pwd` | Print the current working directory |
| `export [VAR=value]` | Set or display environment variables |
| `unset [VAR]` | Remove environment variables |
| `env` | Print the current environment |
| `exit [status]` | Exit the shell with an optional exit code |

## Algorithm

**Main loop — `ft_minishell.c`**

On startup, the shell initializes its internal state via `ft_data_init()`, which duplicates the environment into a private `ms_envp` array and seeds `PWD`. The shell then enters an infinite loop: it registers the appropriate signal handlers, generates a prompt via `ft_get_ps1()`, and calls `readline()` to wait for user input. Each line is passed to `ft_treat_line()`, which drives the rest of the pipeline.

**Data structures — `ft_types.h`**

All runtime state is held in a `t_data` struct: the private environment array (`ms_envp`), the raw input line, the token array (`split_line`), a linked list of parsed commands (`cmd_ll`), and a PID array for forked children. Each node in the command list is a `t_cmd` struct that holds the argument array, input/output file descriptors, a linked list of redirections (`t_redir`), and the operator (`|`, `&&`, or `||`) that connects it to the preceding command.

**History — `ft_treat_line.c`**

Before any processing, `ft_treat_line()` checks for a NULL line (EOF / ctrl-D), which triggers a clean exit. Non-empty lines that differ from the previous entry are added to the readline history with `add_history()`. Consecutive identical commands are not duplicated in history.

**Syntax checking — `ft_check_syntax.c`**

Before any tokenization or expansion, the raw input line is validated by `ft_check_syntax()`. It delegates to four focused checks: `ft_check_unclosed()` for unmatched quotes and parentheses, `ft_check_operators()` for operators at invalid positions (e.g. a line starting with `&&`), `ft_check_redirects()` for redirections missing a target, and `ft_check_empty_parentheses()` / `ft_check_invalid_parentheses()` for malformed subshell groups. Any failure sets exit status 2 and prints a syntax error; the shell then waits for the next command.

**Variable expansion — `ft_expand_variables.c`**

Before tokenization, `ft_args_treatment()` scans the raw line for `$` sequences. Single-quoted regions are skipped entirely. Inside double quotes and unquoted text, each `$NAME` is looked up in `ms_envp` and replaced inline by building a new string of the correct length. The special token `$?` is expanded to the exit status of the last foreground pipeline via `ft_copy_lst_stat()`. Heredoc delimiters are skipped so the `<<` target word is not expanded at this stage.

**Wildcard expansion — `ft_wildcards.c`**

After variable expansion, `ft_wildcards()` scans the (still-unquoted) line for tokens containing `*`. For each wildcard token, `ft_get_names()` reads the current directory with `opendir`/`readdir` and collects all entry names. `ft_search_matches()` checks each name against the pattern segments split by `*`. Matches are joined with spaces and replace the original wildcard token in the line. Quoted `*` characters are skipped. If no entry matches, the literal token is left unchanged.

**Tokenization — `ft_split_prompt.c`**

`ft_split_prompt()` breaks the expanded line into a flat `NULL`-terminated array of tokens. It counts tokens with `ft_count_words()` and then fills the array with `ft_process_word()`. Quoted substrings (single or double) and parenthesized groups are treated as atomic units and are never split on the separator characters. Shell operators (`|`, `||`, `&&`, `<`, `>`, `<<`, `>>`) are always split out as their own tokens, even without surrounding whitespace.

**Parsing — `ft_parser.c`**

`ft_parser()` walks the token array and builds the linked list of `t_cmd` nodes. For each command, `ft_init_cmd()` reads the operator token that opened this segment (e.g. `|`, `&&`), sets up a `pipe()` pair when the operator is a pipe, and then calls `ft_parse_cmd_tokens()` to consume argument tokens and redirection pairs. Redirections are stored as a linked list on the command node. When a heredoc is encountered, `ft_exec_heredoc()` reads lines from standard input until it reaches the delimiter, writes the body into a pipe, and stores the pipe's read end for use as the command's input. In the current implementation this read happens in the shell process, not in a forked process; SIGINT is detected through the shell's status and stops collection.

**Quote removal — `ft_remove_quotes.c`**

After parsing and before execution, `ft_search_quotes()` strips the syntactic quote characters from each argument while preserving the content they enclosed. It handles alternating single and double quote regions correctly, collapsing them into a single unquoted string.

**Execution — `ft_exec_line.c`**

`ft_exec_line()` iterates the command list. For each node it first applies wildcard and quote removal to the argument array. If the first argument starts with `(`, the group is dispatched to `ft_ss()` for subshell execution. If the command is a built-in that is not inside a pipeline, it is executed directly in the parent process by `ft_exec_builtin()`. Otherwise, `fork()` creates a child; file descriptors for completed pipe pairs are closed in the parent after forking. For pipelines, the parent waits only for the last child and then reaps all remaining PIDs. Logical short-circuiting is handled by `ft_skip_based_on_stat()` and `ft_skip_pipeline()`: after a non-piped command finishes, subsequent `&&` commands are skipped on non-zero exit and subsequent `||` commands are skipped on zero exit.

**Child execution — `ft_exec_child.c`**

Inside the child process, `ft_apply_redirs()` opens every file listed in the command's redirection list, calling `dup2()` to wire the final file descriptors and closing all others. The command path is then resolved by `ft_resolve_cmd_path()`, which checks for an absolute or relative path first, then iterates over the `PATH` directories. `execve()` replaces the child with the target program. Appropriate error messages (`command not found`, `Permission denied`, `Is a directory`) are printed when resolution fails, and the child exits with the standard error codes (126 / 127).

**Subshell execution — `ft_subshell.c`**

`ft_ss()` allocates a fresh `t_data` instance, inherits the current environment and last exit status, strips the enclosing parentheses from the argument string, and runs the full expand → tokenize → parse → execute pipeline on that string. The subshell's exit status is returned to the parent, which records it via `ft_get_status()`.

**Signal handling — `ft_signal_handler.c`**

Signal disposition is switched at two points in the main loop. While `readline()` is waiting for input, a `SIGINT` handler clears and redraws the line using the readline API and records exit status 130. While a foreground command is running, a different `SIGINT` handler simply records 130 and prints a newline. `SIGQUIT` is ignored in the shell process at all times. In child processes, both signals are restored to their default disposition with `ft_sigint_default()` / `ft_sigquit_default()` before `execve()`. All handlers use `sigaction` with a properly configured `sigset_t`. The one global variable used (`ft_get_status`, a static local inside the function) stores only the numeric exit status, as required by the subject.

## Resources
[readline(3) — GNU manual](https://tiswww.case.edu/php/chet/readline/rltop.html)  
[history(3) - Linux man page](https://linux.die.net/man/3/history)  
[execve(2) — Linux manual page](https://www.man7.org/linux/man-pages/man2/execve.2.html)  
[fork(2) — Linux manual page](https://www.man7.org/linux/man-pages/man2/fork.2.html)  
[pipe(2) — Linux manual page](https://www.man7.org/linux/man-pages/man2/pipe.2.html)  
[sigaction(2) — Linux manual page](https://www.man7.org/linux/man-pages/man2/sigaction.2.html)  
[dup2(2) — Linux manual page](https://www.man7.org/linux/man-pages/man2/dup.2.html)  
[Bash Reference Manual — GNU](https://www.gnu.org/software/bash/manual/bash.html)  
[Programming with GNU Readline](https://web.mit.edu/gnu/doc/html/rlman_2.html)  
[LucasKun - minishell_tester](https://github.com/LucasKuhn/minishell_tester)  

**AI Usage**

AI was used to help write this README.
