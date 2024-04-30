function ParseToken(numb)
	return table.keysFromValue(TOKENTYPES, numb)[1]
end
TokenMeta = {
	__tostring = function(self)
		return ParseToken(self[1]) .. " " .. tostring(self[2] or "") .. " Ln: " .. (self[3] or "0") .. " Col: " .. (self[4] or "0")
	end,
}
TOKENTYPES = {
	EOF = 0,

	PLUS = 1, -- +
	MINUS = 2, -- -
	STAR = 3, -- *
	SLASH = 4, -- /
	FLEX = 5, -- ^
	MODULE = 6, -- %

	LBRACKET = 7, -- (
	RBRACKET = 8, -- )
	LBR = 9, -- {
	RBR = 10, -- }

	COMMA = 11, -- ,
	EQ = 12, -- =
	EXCL = 13, -- !
	LT = 14, -- <
	GT = 15, -- >
	AMP = 16, -- &
	BAR = 17, -- |

	EQEQ = 18, -- ==
	LTEQ = 19, -- <=
	GTEQ = 20, -- >=
	EXCLEQ = 21, -- !=
	AMPAMP = 22, -- &&
	BARBAR = 23, -- ||

	PLUSEQ = 24, -- +=
	PLUSPLUS = 25, -- ++
	MINUSEQ = 26, -- -=
	MINUSMINUS = 27, -- --
	STAREQ = 28, -- *=
	FLEXEQ = 29, -- ^=
	SLASHEQ = 29, -- /=

	WORD = 30, -- anyword
	NUMBER = 31, -- 1
	STRING = 32, -- "TEXT"
	IF = 33,
	ELSE = 34,
	FOR = 35,
	WHILE = 36,
	BREAK = 37,
	CONTINUE = 38,
	ENDBLOCK = 39, -- ;
	CONCAT = 40, -- ..
	FUNCTION = 41, -- fn
	RETURN = 42, -- return
	EXPORT = 43,
	LAMBDA = 44,

	CLASSDEF = 45, -- class
	CLASSCONSTRUCTOR = 46, -- constructor
	CLASSNEW = 47, -- new
	POINT = 48, -- .
	FSTRING = 49,
	POINTER = 50,
	EXTENDS = 51,
	THIS = 52,
	OPENTBL = 53,
	CLOSETBL = 54,
	ASYNC = 55,
	AWAIT = 56,
	HEX = 57, -- 0xff
	BINARY = 58,
	VAR = 59,
	IMPORT = 60,
	FROM = 61,
	KEYKARD = 62,
	STATIC = 63,
	PRIVATEVAR = 64,
	IN = 65,
	CLASSSTATE = 66,
	READONLY = 67,
	PUB = 68,
	PATH = 69,
	CONST = 70,
	STRUCT = 71,
	IMPL = 72,
	RANGE = 73,
	USE = 74,
	AS = 75,
	VARARGS = 76,
	TRAIT = 77,
	BOX = 78,
	EXTERN = 79,
}
