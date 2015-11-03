
codeToChar = (code) -> String.fromCharCode(code)[0]
charToCode = (char) -> char.charCodeAt()

class VM

  constructor: ->
    @pointer = 0
    @position = 0
    @buffer = {}
    @input = []
    @output = []
    @program = []
    @stack = []
    @loops = {}

  load: (program, input) ->

    cleanProgram = []
    for instruction in program
      if instruction in ['>', '<', '+', '-', ',', '.', '[', ']']
        cleanProgram.push(instruction)
    stack = []
    for position, instruction of cleanProgram
      if instruction == '['
        stack.push(position)
      if instruction == ']'
        initpos = stack.pop()
        if not initpos?
          throw 'Syntax error:' + position
        @loops[initpos] = position
      @program.push instruction

    if @program.length == 0
      throw "Empty program"

    if stack.length != 0
      throw 'Syntax error:' + position

    for char in input
      @input.push charToCode(char)

    @checkbuffer()

  runStep: ->
    instruction = @program[@position]
    if not instruction
      return true
    else
      @[instruction]()
      @position++
      return false

  outputString: -> (codeToChar(code) for code in @output when code != 0).join('')
  inputString: ->  (codeToChar(code) for code in @input  when code != 0).join('')

  checkbuffer: ->
    @buffer[@pointer] = @buffer[@pointer] ? 0

  '>': ->
    @pointer += 1
    @checkbuffer()

  '<': ->
    @pointer -= 1
    @checkbuffer()

  '+': ->
    @buffer[@pointer] += 1
    @buffer[@pointer] = 0 if @buffer[@pointer] > 255

  '-': ->
    @buffer[@pointer] -= 1
    @buffer[@pointer] = 255 if @buffer[@pointer] < 0

  ',': ->
    if @input.length == 0
      @buffer[@pointer] = 0
      return

    value = @input.splice(0, 1)[0]
    @buffer[@pointer] = value

  '.': ->
    @output.push(@buffer[@pointer])

  '[': ->
    if (@buffer[@pointer] != 0)
      @stack.push(@position - 1)
    else
      @position = @loops[@position]

  ']': ->
    @position = @stack.pop()

runFor = (ms, f, k) ->
	start = process.hrtime()
	if f()
		k(true)
	else if process.hrtime() - start > ms
		k(false)
	else
		setImmediate () -> runFor ms, f, k

module.exports = (robot) ->
	robot.respond /bf (.*)/, (res) ->
		vm = new VM()
		vm.load res.match[1], []
		step = () -> vm.runStep()
		replyPlease = (v) -> reply res, v
		runFor 2000, step, replyPlease
		reply = (res, v) ->
			if v
				value = vm.outputString()
				if value == ""
					res.send "try again"
				else
					res.send "Output: #{value}"
					console.log "Brainfuck Output: #{value}"
