/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_minishell.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: alebarbo <alebarbo@student.42porto.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/09/29 21:46:59 by alebarbo          #+#    #+#             */
/*   Updated: 2026/04/18 01:34:32 by alebarbo         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <ft_minishell.h>

unsigned char	ft_get_status(unsigned char last_status, bool flag)
{
	static unsigned char	status;

	if (flag)
		status = last_status;
	return (status);
}

int	main(int argc, char *argv[], char *envp[])
{
	t_data	*dt;
	t_data	**dt_arr;

	(void) argc;
	(void) argv;
	ft_sigquit_listener();
	dt = ft_data_init(envp);
	dt_arr = ft_create_dt_arr(dt);
	while (1)
	{
		dt->last_status = ft_get_status(0, false);
		ft_get_status(0, true);
		ft_sigint_readline_listener();
		dt->prompt = ft_get_ps1(dt->ms_envp);
		dt->line = readline(dt->prompt);
		ft_sigint_listener();
		if (ft_get_status(0, false) == 130)
		{
			dt->last_status = ft_get_status(0, false);
			ft_get_status(0, true);
		}
		ft_treat_line(dt_arr, dt);
		ft_free_prompt_line(dt);
	}
}
