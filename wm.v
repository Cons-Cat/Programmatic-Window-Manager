module main

import cli
import os

fn main() {
	mut app := cli.Command{
		name: 'conscat'
		description: "conscat's window manager"
	}
	mut focus_cmd := cli.Command{
		name: 'focus'
		usage: '<app>'
		required_args: 1
		execute: main_callback
	}
	focus_cmd.add_flag(cli.Flag{
		flag: .string
		required: false
		name: 'window'
		abbrev: 'w'
	})
	app.add_command(focus_cmd)
	app.setup()
	app.parse(os.args)
}

enum ScreenStates {
	screen
	min_width
	min_height
	cur_width
	cur_height
	max_width
	max_height
}

struct Position {
	states []int
}

fn (p Position) build_mvargs() string {
	mut mvargs := ''
	for s in p.states {
		mvargs += s.str() + ','
	}
	return mvargs
}

fn main_callback(cmd cli.Command) ? {
	screen_states := os.execute("xrandr -q | rg 'current' | rg -o '[0-9]+'").output.split('\n')
	screen := screen_states[ScreenStates.screen].int()
	screen_width := screen_states[ScreenStates.cur_width].int()
	screen_height := screen_states[ScreenStates.cur_height].int()
	half_screen_width := screen_width / 2
	half_screen_height := screen_height / 2
	input := os.args_after('focus')[1]
	// For some reason, 'conscat' is the 0th element.
	pos := match input {
		'kitty' {
			Position{[screen, half_screen_width, 0, half_screen_width, screen_height]}
		}
		else {
			Position{[0, 0, 0, 600, 300]}
		}
	}
	find_or_launch(input, pos)
}

fn find_or_launch(name string, pos Position) {
	result := os.execute('jumpapp ' + name)
	if result.exit_code == 0 {
		os.execute('wmctrl -r :ACTIVE: -e $pos.build_mvargs()')
		println(pos.build_mvargs())
	} else {
		panic('Failed to focus on $name!')
	}
}
