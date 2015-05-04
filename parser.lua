local parse = {}

require 'lxsh'
local js = require 'js_lexer'
local util = require 'util'

local file = io.open(arg[1],"r")
local src = file:read("*a")
print(src)
io.close(file)

local cursor = 0
local current

--local generated_code = ""

local gen_table = {}
--local tree = {}

for kind, text, lnum, cnum in js.gmatch(src) do
	print(string.format('%s: %q (%i:%i)', kind, text, lnum, cnum))
	if kind ~= 'comment' and kind ~= 'whitespace' then
		table.insert(gen_table,{kind = kind, text = text, line = lnum})
	end
end

function parse.next()
	cursor = cursor+1
	current = gen_table[cursor]
	return current
end

function parse.showNext()
	return gen_table[cursor+1]
end


function parse.expect(tokenKind)
	local token = parse.next()
	if token.kind ~= tokenKind then
		error("Parsing error on line "..token.line..". Expecting "..tokenKind.." but got "..token.kind..".")
	end
	return token
end

function parse.call()
	parse.expect('rightpar')
end

local function auxExp()
	--while util.in_table({'+','-','*','/','%'},(parse.showNext()).text) do
	while (parse.showNext()).kind == 'operator' do
		parse.next()
		parse.expression()
	end
end

function parse.expression()
	print("Parsing Expression")
	local token = parse.showNext()
	if token.kind == 'number' then
		parse.next()
		auxExp()
	elseif token.kind == 'identifier' then
		parse.next()
		local token = parse.showNext()
		if token.kind == 'leftpar' then
			parse.call()
		else
			auxExp()
		end
	else
		error("Parsing error on line "..token.line..".")
	end	
end

function parse.declaration()
	print("Parsing Declaration")
	parse.expect('identifier')
	parse.expect('assign')
	-- TODO  declare funcs
	parse.expression()
	parse.expect('semicolon')
end

function parse.stIf()
	print("Parsing If")
	parse.expect('leftpar')
	parse.expression()
	parse.expect('rightpar')
	parse.expect('leftcurly')
	-- TODO end of if statement
end

function parse.assign()
	-- TODO
end

function parse.stmt()
	print("Parsing Statement")
	local token = parse.showNext()
	-- DECLARATION
	if token.kind == 'var' then
		parse.next()
		parse.declaration()

	-- IF
	elseif token.kind == 'if' then
		parse.next()
		parse.stIf()

	elseif token.kind == 'identifier' then
		parse.next()
		local token = parse.showNext()

		-- FUNCTION CALL
		if token.kind == 'leftpar' then
			parse.call()

		-- ASSIGNMENT
		else
			parse.assign()
		end
	else -- TODO: while, for, etc
		error("Parsing error on line "..token.line..". Expected ?, got "..token.kind)
	end
	
end

while parse.showNext() do
	parse.stmt()
end
