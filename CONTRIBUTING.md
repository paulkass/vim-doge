# Contribution Guidelines

To keep consistency within the codebase, several guidelines will be required
when contributing to the repository. The topics below will also contain small
checklists to keep in mind when contributing.

When contributing make sure you:
- have read and understood the [Code of Conduct](./CODE_OF_CONDUCT.md).
- are working from the `develop` branch
- submit your PR to the `develop` branch.

# Table of Contents
- [Contribution Guidelines](#contribution-guidelines)
- [Table of Contents](#table-of-contents)
- [How does DoGe work?](#how-does-doge-work)
- [Topics](#topics)
  * [Linting](#linting)
  * [Documentation](#documentation)
  * [Filetype / language](#filetype--language)
  * [Configurable setting](#configurable-setting)
  * [Code](#code)
  * [Tests](#tests)
- [Tips](#tips)
  * [Writing your first pattern](#writing-your-first-pattern)
    + [Additional token formatting](#additional-token-formatting)
      - [Default value](#default-value)
      - [Conditional rendering](#conditional-rendering)
  * [Writing proper regex](#writing-proper-regex)

# How does DoGe work?

The key to DoGe is _regex_. Why? Because of its flexibility. Each filetype
consists of a buffer-local variable named `b:doge_patterns` which is a list of
dictionaries containing info about the pattern to match and how the comment
should be structured.

In each pattern you can specify a regex pattern, each group can be named and
each name can be used as a token inside other specific keys.

After implementing this the only thing left to do is implementing all the
languages.

# Topics

Below will be several topics describing their minimum requirements when
contributing.

## Linting

Your pull request should follow the rules of the `vim-vint` linter which is a
must to keep the code clean and prevent mistakes being made. Each PR will
automatically run tests for code quality using Vint. You don't have to use Vint
locally, but it will help you to fix any errors before submitting a PR.

- `pip3 install vim-vint`

If you use [ALE](https://github.com/w0rp/ale) (recommended)

```
let g:ale_linters = { 'vim': ['vint'] }
```

or if you use [Syntastic](https://github.com/vim-syntastic/syntastic)
```
let g:syntastic_vim_checkers = ['vint']
```

## Documentation

Try to document all functions and configurable options where needed. The
documentation in the `doc/doge.txt` should be generated using
[vimdoc](https://github.com/google/vimdoc).

## Filetype / language

When adding a new filetype/language to DoGe there is a lot to take into
account. Assuming you know the language ins and outs, it is recommended for
everyone to add a `playground` file with all possible scenarios. This helps to
write good regex since you know all the possible scenarios and more important:
this will help a lot when writing tests, because you already have the
scenarios. This can also help debugging when regex is not working as expected.

**Summary of requirements:**
- Playground file (located at `playground/test.<ext>`)
- ftplugin
  - Top comment describing what doc standard it should follow.
  - `b:doge_pattern_single_line_comment` (Used to strip comments before generating)
  - `b:doge_pattern_multi_line_comment` (Used to strip comments before generating)
  - `b:doge_supported_doc_standards` (A list containing the available doc standards)
  - `b:doge_doc_standard` (Contains the preferred doc standard by the user with a fallback to the first item of `b:doge_supported_doc_standards`)
  - For each pattern a comment with example scenarios that it should match. See [Writing your first pattern](#writing-your-first-pattern) for more info.
- Tests (located in `test/filetypes/<filetype>/`)
- Add your new language to the main [README](./README.md).

## Configurable setting

When adding a new global-configurable setting then it should use proper
[vimdoc](https://github.com/google/vimdoc) syntax and documentation with the
default value, a brief description of what is does and tests.

**Summary of requirements:**
- Add the setting in `plugin/doge.vim`.
  - Add the default value
  - Add a brief description of what it does
- Install [vimdoc](https://github.com/google/vimdoc) and run `vimdoc .`
  locally. If no errors were given, the `doc/doge.txt` should be updated.
- Open vim and run `:helptags ~/.vim/path/to/your/local/doge/doc`. This should
  update the `tags` file located at `doc/tags`.
- Tests (located at `test/options/<option-name>.vader`)

## Code

When none of the above applies to your contribution you're probably
contributing a bug fix or a new feature.

Depending on how big your feature is, it might need some tests. If it is a
bug fix then no tests are required.

Make sure to document code where needed and keep the [README](./README.md),
[doge.txt](./doc/doge.txt) and [tags](./doc/tags) file updated.

## Tests

Running tests can be done by simply running `./run-tests`.
Use `./run-tests --help` for more info about the usage.

# Tips

Below will be some helpful tips for contributing.

## Writing your first pattern

If you have looked through the `ftplugin` folder through some files you have
noticed the buffer-local variable patterns. Below will be some explanation
about the dictionary structure per pattern.

The generation is done using the patterns as the following:
- Start by matching the given pattern.
- Extract all the tokens using the `match_group_names`.
  - Extract the parameter tokens based on the `parameter` token.
- Render the tokens in the `template`.

```vim
" Example taken from ftplugin/php.vim

call add(b:doge_patterns, {
   " The 'match' key is the main pattern to detect the actual expression.
   " The example below will match: 'public static function myFunc($p1 = NULL) {'
   " NOTE: The 'match' key should always start with \m to force magic notation
   " and start with ^ to make sure it's not matching in middle.
\  'match': '\m^\%(\%(public\|private\|protected\|static\|final\)\s\+\)*function\s*\([^(]\+\)\s*(\(.\{-}\))\s*{',

   " The 'match_group_names' are names for the captured groups where the index
   " is equivalent to the captured groups' index. These names become tokens
   " that can be used in the 'template' key.
\  'match_group_names': ['funcName', 'parameters'],

   " The 'parameters' key is an optional key, since not every expression has a
   " parameter list.
\  'parameters': {
     " The 'match' key is a pattern describing a single parameter. DoGe will
     " strip matches until none are found. For example:
     " PHP is using the parameter syntax pattern:
     "   '<param-type> $<param-name> = <param-default-value>'.
     " So when this ^ is your pattern, you should write the regex for that.
     " NOTE: The 'match' key should start with \m to force magic notation and
     " should not contain ^ at the beginning or $ at the end.
\    'match': '\m\%(\([[:alnum:]_\\]\+\)\s\+\)\?&\?\($[[:alnum:]_]\+\)\%(\s*=\s*\%([[:alnum:]_]\+(.\{-})\|[^,]\+\)\+\)\?',

     " The 'match_group_names' are names for the captured groups where the index
     " is equivalent to the captured groups' index. These names become tokens
     " that can be used in the 'format' key.
\    'match_group_names': ['type', 'name'],

     " The 'format' key describes how the format of each parameter should be.
     " It contains a format for each supported doc standard.
     " Use a list for multi-line.
     " Use a tab '\t' to indent properly based on the user setting.
\    'format': {
\      'phpdoc': '@param {type|mixed} {name} TODO',
\    },
\  },

   " The 'comment' key determines how to generate the final comment.
\  'comment': {

     " The 'insert' key may contain the value 'above' or 'below'.
     " Examples:
     " - PHP comments will be inserted above the function expression.
     " - Python comments will be inserted below the function expression.
\    'insert': 'above',

     " The 'template' key is a dictonary containing a list for each doc standard.
     " Each key in the template list is a new line when rendering the comment.
\    'template': {
\      'phpdoc': [
\        '/**',
\        ' * TODO',
\        '#(parameters| *)',
\        '#(parameters| * {parameters})',
\        ' */',
\      ],
\    },
\  },
\})
```

### Additional token formatting

Additional formatting is available when using tokens in the `template` or
`parameters.format` keys.

#### Default value

You can render a token using the format `{...}`. When the captured group failed
to capture a value you can specify a default value using the pipe character
`|` like so: `{...|my default value}`.

For example:
PHP uses `mixed` as a type when the variable has no type hint specified. You
can accomplish this by render the `{type}` token as `{type|mixed}`. This will
result in `* @param mixed $myVar TODO` instead of `* @param {type} $myVar TODO`.

You can also leave the default value empty to just remove the token when it
fails to capture a value. Example: `{type|}`. This will result in:
`* @param $p1 TODO` instead of `* @param {type} $p1 TODO`.

#### Conditional rendering

The syntax for a conditional render is `#(<token>|<value>)` where `<token>` is
the name of the token and `<value>` the value you want to render when `<token>`
is _not empty_.

Example:

```vim
" Example taken from ftplugin/python.vim

call add(b:doge_patterns, {
\  " ...
\  'comment': {
\    'insert': 'below',
\    'template': {
\      'numpy': [
\        '"""',
\        'TODO',
\        '#(parameters|)',              " Render an empty line if '{parameters}' is not empty
\        '#(parameters|Parameters)',    " Renders 'Parameters' if '{parameters}' is not empty
\        '#(parameters|----------)',    " Renders '----------' if '{parameters}' is not empty
\        '#(parameters|{parameters})',  " Renders '{parameters}' if '{parameters}' is not empty
\        '"""',
\      ],
\    }
\  },
\})
```

## Writing proper regex

The main part of DoGe is regular expressions and before writing any regex, you
should know how DoGe will give you input.

To make DoGe work for many languages and prevent parsing every single language,
DoGe grabs the first 15 lines of code below the cursor and will concatenate all
the lines using a single whitespace character `' '`. This is also due to
function declarations can be declared multi-line.

Consider the following PHP example where `|` indicates the cursor:

```php
<?php

|function myFuncA(
  array $p1,
  string $p2,
  int $p3,
  bool $p4,
  Entity $p5,
  Node $p6,
)
{
  //
}

function myFuncA(
  bool $p1,
  Entity $p2,
  Node $p3,
)
{
  //
}
```

If you trigger DoGe you will receive as input (line 3 - 18) as a single string:
```
function myFuncA(   array $p1,   string $p2,   int $p3,   bool $p4,   Entity $p5,   Node $p6, ) {   // }  function myFuncA(   bool $p1,   Entity $p2,   Node $p3,
```
and this is where you should write your regex for. This requires you to write a
non-greedy regex to ensure no parameters will be taken from the function defined
below the one you're generating documentation for.

If you need help with your regex you can visit the IRC Freenode #regex or #vim channel
or [ask a question](https://github.com/kkoomen/vim-doge/issues/new?labels=question&template=question.md) in the issue tracker.
