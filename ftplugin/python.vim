" ==============================================================================
" The Python documentation should follow the 'reST' or 'Numpy' conventions.
" see:
" - reST: http://daouzli.com/blog/docstring.html#restructuredtext
" - Numpy: http://daouzli.com/blog/docstring.html#numpydoc
" ==============================================================================

let s:save_cpo = &cpoptions
set cpoptions&vim

let b:doge_pattern_single_line_comment = '\m#.\{-}$'
let b:doge_pattern_multi_line_comment = '\m\(""".\{-}"""\|' . "'''.\\{-}'''" . '\)'

let b:doge_supported_doc_standards = ['reST', 'numpy']
let b:doge_doc_standard = get(g:, 'doge_doc_standard_python', 'reST')
if index(b:doge_supported_doc_standards, b:doge_doc_standard) < 0
  echoerr printf(
        \ '[DoGe] %s is not a valid Python doc standard, available doc standard are: %s',
        \ b:doge_doc_standard,
        \ join(b:doge_supported_doc_standards, ', ')
        \ )
endif

let b:doge_patterns = []

" ==============================================================================
" Matches regular function expressions and class methods.
" ==============================================================================
"
" Matches the following scenarios:
"
"   def __init__(self: MyClass):
"
"   def myMethod(self: MyClass, p1: Sequence[T]) -> Generator[int, float, str]:
"
"   def call(self, *args: str, **kwargs: str) -> str:
"
"   def myFunc(p1: Callable[[int], None] = False, p2: Callable[[int, Exception], None]) -> Sequence[T]:
call add(b:doge_patterns, {
\  'match': '\m^def\s\+\%([^(]\+\)\s*(\(.\{-}\))\%(\s*->\s*\(.\{-}\)\)\?\s*:',
\  'match_group_names': ['parameters', 'returnType'],
\  'parameters': {
\    'match': '\m\([[:alnum:]_]\+\)\%(:\s*\([[:alnum:]_]\+\%(\[[[:alnum:]_[\],[:space:]]*\]\)\?\)\)\?\%(\s*=\s*\([^,]\+\)\)\?',
\    'match_group_names': ['name', 'type'],
\    'format': {
\      'reST': ':param {name} {type|any}: TODO',
\      'numpy': [
\        '{name} : {type|any}',
\        "\tTODO",
\      ],
\    },
\  },
\  'comment': {
\    'insert': 'below',
\    'template': {
\      'reST': [
\        '"""',
\        'TODO',
\        '',
\        '#(parameters|{parameters})',
\        '#(returnType|:rtype {returnType}: TODO)',
\        '"""',
\      ],
\      'numpy': [
\        '"""',
\        'TODO',
\        '',
\        'TODO',
\        '#(parameters|)',
\        '#(parameters|Parameters)',
\        '#(parameters|----------)',
\        '#(parameters|{parameters})',
\        '#(returnType|)',
\        '#(returnType|Returns)',
\        '#(returnType|-------)',
\        '#(returnType|{returnType|any}:)',
\        "#(returnType|\tTODO)",
\        '"""',
\      ],
\    },
\  },
\})

let &cpoptions = s:save_cpo
unlet s:save_cpo
