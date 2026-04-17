# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: alebarbo <alebarbo@student.42porto.com>    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/09/29 20:54:21 by alebarbo          #+#    #+#              #
#    Updated: 2026/04/17 18:20:08 by alebarbo         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#==============================================================================#
#                                 COLOR CODES                                  #
#==============================================================================#
RED		= \033[0;31m
GREEN	= \033[0;32m
YELLOW	= \033[0;33m
BLUE	= \033[0;34m
RESET	= \033[0m

#==============================================================================#
#                                  VARIABLES                                   #
#==============================================================================#

# Names
NAME			= minishell
NAME_BONUS		= minishell_bonus
PROJECT_NAME	= MINISHELL

# Paths
SRC_PATH		= srcs
SRC_PATH_BONUS	= srcs_bonus
INC_PATH		= incs
BUILD_PATH		= .build

# Source files
SRC = $(addprefix $(SRC_PATH)/, \
		ft_minishell.c \
		ft_apply_redirs.c \
		ft_change_directory.c \
		ft_check_syntax_utils.c \
		ft_check_syntax.c \
		ft_cleanup_line.c \
		ft_copy_lst_stat.c \
		ft_data_init.c \
		ft_dup2_close.c \
		ft_exec_builtin.c \
		ft_exec_child.c \
		ft_exec_line.c \
		ft_exec_utils.c \
		ft_echo.c \
		ft_env.c \
		ft_env_utils.c \
		ft_exit.c \
		ft_expand_envp.c \
		ft_expand_heredoc.c \
		ft_expand_variables_utils.c \
		ft_expand_variables.c \
		ft_export_vars.c \
		ft_export.c \
		ft_free.c \
		ft_get_names.c \
		ft_get_ps1.c \
		ft_is_op.c \
		ft_match_wildcards.c \
		ft_parser_utils.c \
		ft_parser.c \
		ft_print_ordered_exp.c \
		ft_puterror.c \
		ft_pwd.c \
		ft_remove_quotes.c \
		ft_resolve_cmd_path.c \
		ft_shlvl.c \
		ft_signal_default.c \
		ft_signal_handler.c \
		ft_skips.c \
		ft_split_prompt_utils_2.c \
		ft_split_prompt_utils.c \
		ft_split_prompt.c \
		ft_str_to_fd.c \
		ft_strarr_dup.c \
		ft_subshell.c \
		ft_treat_line.c \
		ft_wildcards.c \
		ft_wildcards_utils.c \
		ft_unset.c \
)
SRC_BONUS = $(filter-out $(SRC_PATH)/ft_minishell.c, $(SRC)) \
	$(addprefix $(SRC_PATH_BONUS)/, ft_minishell_bonus.c)

# Object files
OBJ = $(addprefix $(BUILD_PATH)/, $(notdir $(SRC:.c=.o)))
OBJ_BONUS = $(addprefix $(BUILD_PATH)/, $(notdir $(SRC_BONUS:.c=.o)))

# LIBFT
LIBFT_PATH		= libft
LIBFT_INC_PATH	= $(LIBFT_PATH)/includes
LIBFT_LINK		= ft
LIBFT_NAME		= $(LIBFT_PATH)/lib$(LIBFT_LINK).a

# Compiler and Flags
# MAKEFLAGS += -s
CC		= cc
CFLAGS	= -Wall -Wextra -Werror -ggdb
INC		= -I$(INC_PATH) -I$(LIBFT_INC_PATH)
LDFLAGS	= -L$(LIBFT_PATH) -l$(LIBFT_LINK) -lreadline

# Utility Commands
RM		= rm -f
MKDIR_P	= mkdir -p
RMDIR	= $(RM) -r
MAKE	= make --no-print-directory

.PHONY: all clean fclean re bonus

all: $(NAME)

$(NAME): $(OBJ) $(LIBFT_NAME)
	@$(RM) $(NAME_BONUS)
	@$(CC) $(CFLAGS) $(INC) $(OBJ) $(LDFLAGS) -o $@
	@echo "$(GREEN)[$(PROJECT_NAME)] Executable compiled: $(NAME).$(RESET)"

$(BUILD_PATH)/%.o: $(SRC_PATH)/%.c | $(BUILD_PATH)
	@$(CC) $(CFLAGS) $(INC) -c $< -o $@

$(BUILD_PATH):
	@$(MKDIR_P) $(BUILD_PATH)
	@echo "$(GREEN)[$(PROJECT_NAME)] Build directory created.$(RESET)"

$(LIBFT_NAME):
	@$(MAKE) -C $(LIBFT_PATH) all

clean:
	@$(RMDIR) $(BUILD_PATH)
	@$(MAKE) -C $(LIBFT_PATH) clean
	@echo "$(RED)[$(PROJECT_NAME)] Clean: Cleaned object files.$(RESET)"

fclean: clean
	@$(RM) $(NAME) $(NAME_BONUS)
	@$(MAKE) -C $(LIBFT_PATH) fclean
	@echo "$(RED)[$(PROJECT_NAME)] Full Clean: executables $(NAME) $(NAME_BONUS) removed.$(RESET)"

re: fclean all

bonus: $(NAME_BONUS)

$(NAME_BONUS): $(OBJ_BONUS) $(LIBFT_NAME)
	@$(RM) $(NAME)
	@$(CC) $(CFLAGS) $(INC) $(OBJ_BONUS) $(LDFLAGS) -o $@
	@echo "$(GREEN)[$(PROJECT_NAME)] Executable compiled: $(NAME_BONUS).$(RESET)"

$(BUILD_PATH)/%.o: $(SRC_PATH_BONUS)/%.c | $(BUILD_PATH)
	@$(CC) $(CFLAGS) $(INC) -c $< -o $@
