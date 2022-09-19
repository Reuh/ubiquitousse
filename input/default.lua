 return {
	move = {
		"clamped(child.right - child.left, child.down - child.up)",
		dimension = 2,
		right = { "scancode.right", "scancode.d", "axis.leftx.p", "button.dpright" },
		left = { "scancode.left", "scancode.a", "axis.leftx.n", "button.dpleft" },
		down = { "scancode.down", "scancode.s", "axis.lefty.p", "button.dpdown" },
		up = { "scancode.up", "scancode.w", "axis.lefty.n", "button.dpup" },
	},
	confirm = { "scancode['return']", "scancode.space", "scancode.e", "button.a" },
	cancel = { "scancode.escape", "scancode.backspace", "button.b" },
}
