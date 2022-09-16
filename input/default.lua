 return {
	move = {
		horizontal = {
			"child.positive - child.negative",
			positive = { "scancode.right", "scancode.d", "axis.leftx.p", "button.dpright" },
			negative = { "scancode.left", "scancode.a", "axis.leftx.n", "button.dpleft" },
		},
		vertical = {
			"child.positive - child.negative",
			positive = { "scancode.down", "scancode.s", "axis.lefty.p", "button.dpdown" },
			negative = { "scancode.up", "scancode.w", "axis.lefty.n", "button.dpup" },
		},
	},
	confirm = { "scancode['return']", "scancode.space", "scancode.e", "button.a" },
	cancel = { "scancode.escape", "scancode.backspace", "button.b" },
}
