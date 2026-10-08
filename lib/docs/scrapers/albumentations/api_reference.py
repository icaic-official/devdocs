"""Writes albumentations' API reference as HTML, from the docstrings.

Usage: python3 api_reference.py <albumentations checkout> <output directory>

albumentations.ai documents AlbumentationsX, the successor of the
albumentations package, and the old site's sources aren't public, so the
reference of the last albumentations release is generated from its source.
The modules are parsed with `ast` rather than imported, so neither
albumentations nor its dependencies need to be installed.

Writes a page per public module (those whose names `import albumentations as A`
exposes) with a section per exported class or function, an index.html whose "<!-- README -->" placeholder the scraper
replaces with parts of the README, and names.json mapping every public name to
the page and anchor documenting it. Docstrings are in the Google style.
"""

import ast
import html
import json
import os
import re
import sys
import textwrap

# Module (relative to the package) => group, in the order of the index page.
# These are the modules `albumentations/__init__.py` star-imports, directly or
# through `augmentations/__init__.py`; the `functional` and `*_utils` modules
# behind them aren't exported.
MODULES = [
    ('augmentations/blur/transforms', 'Blur'),
    ('augmentations/crops/transforms', 'Crops'),
    ('augmentations/dropout/channel_dropout', 'Dropout'),
    ('augmentations/dropout/coarse_dropout', 'Dropout'),
    ('augmentations/dropout/grid_dropout', 'Dropout'),
    ('augmentations/dropout/mask_dropout', 'Dropout'),
    ('augmentations/dropout/transforms', 'Dropout'),
    ('augmentations/dropout/xy_masking', 'Dropout'),
    ('augmentations/geometric/distortion', 'Geometric'),
    ('augmentations/geometric/flip', 'Geometric'),
    ('augmentations/geometric/pad', 'Geometric'),
    ('augmentations/geometric/resize', 'Geometric'),
    ('augmentations/geometric/rotate', 'Geometric'),
    ('augmentations/geometric/transforms', 'Geometric'),
    ('augmentations/mixing/domain_adaptation', 'Mixing'),
    ('augmentations/mixing/transforms', 'Mixing'),
    ('augmentations/other/lambda_transform', 'Other'),
    ('augmentations/other/type_transform', 'Other'),
    ('augmentations/pixel/transforms', 'Pixel'),
    ('augmentations/spectrogram/transform', 'Spectrogram'),
    ('augmentations/text/transforms', 'Text'),
    ('augmentations/transforms3d/transforms', '3D'),
    ('augmentations/utils', 'Utilities'),
    ('core/composition', 'Core: Composition'),
    ('core/serialization', 'Core: Serialization'),
    ('core/transforms_interface', 'Core: Transforms interface'),
    ('pytorch/transforms', 'PyTorch'),
]

# Modules whose classes' public methods are documented too: they're the
# interfaces users call or override. The transforms' apply* methods aren't.
WITH_METHODS = {'core/composition', 'core/transforms_interface'}

ARGS = {'Args', 'Arguments', 'Parameters', 'Attributes'}
DEFINITIONS = {'Returns', 'Return', 'Yields', 'Raises'}
FACTS = {'Targets', 'Image types', 'Supported image types', 'Number of channels'}
PROSE = {
    'Note', 'Notes', 'Examples', 'Example', 'References', 'Reference', 'See Also', 'Warning', 'Warnings',
    'Implementation Details',
}
FORMULAS = re.compile(r'\AMathematical (Formulation|Details|formulation|Background)\Z')
SECTION = re.compile(r'\A([A-Z][A-Za-z ]+):\s*\Z')
LIST_ITEM = re.compile(r'\A([-*+•]|\d+[.)])\s+')
URL = re.compile(r'(https?://[^\s<>"\')\]]+[^\s<>"\')\].,;:])')

SIGNATURE_WIDTH = 80


def main(repository, output):
    package = Package(os.path.join(repository, 'albumentations'))
    names = {}
    exports = {}
    for module, _ in MODULES:
        exports[module] = exported_names(package.tree(module))
        for name in exports[module]:
            names[name] = f'{module}.html#{name}'

    renderer = Renderer(package, names)
    for module, group in MODULES:
        path = os.path.join(output, module + '.html')
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as file:
            file.write(renderer.module_page(module, group, exports[module]))

    with open(os.path.join(output, 'index.html'), 'w', encoding='utf-8') as file:
        file.write(index_page(exports))
    with open(os.path.join(output, 'names.json'), 'w', encoding='utf-8') as file:
        json.dump(names, file, indent=1, sort_keys=True)


class Package:
    """Parses the package's modules and finds the definitions of the names they export."""

    def __init__(self, root):
        self.root = root
        self.trees = {}

    def tree(self, module):
        if module not in self.trees:
            path = os.path.join(self.root, module + '.py')
            if not os.path.exists(path):
                path = os.path.join(self.root, module, '__init__.py')
            with open(path, encoding='utf-8') as file:
                self.trees[module] = ast.parse(file.read())
        return self.trees[module]

    def definition(self, module, name, seen=()):
        """Returns the class or function node `name` refers to in `module`, following relative imports."""
        if (module, name) in seen:
            return None
        tree = self.tree(module)
        for node in tree.body:
            if isinstance(node, (ast.ClassDef, ast.FunctionDef)) and node.name == name:
                return node
        for node in tree.body:
            if isinstance(node, ast.ImportFrom) and node.level and any(alias.name == name for alias in node.names):
                base = module.split('/')[:-node.level] if node.level else []
                target = '/'.join(base + (node.module.split('.') if node.module else []))
                return self.definition(target, name, (*seen, (module, name)))
            if isinstance(node, ast.ImportFrom) and node.module and node.module.startswith('albumentations.') and any(alias.name == name for alias in node.names):
                target = node.module.split('.', 1)[1].replace('.', '/')
                return self.definition(target, name, (*seen, (module, name)))
        return None


def exported_names(tree):
    for node in tree.body:
        if isinstance(node, ast.Assign) and any(getattr(target, 'id', None) == '__all__' for target in node.targets):
            exported = [element.value for element in node.value.elts]
            # In the order of the source
            order = [n.name for n in tree.body if isinstance(n, (ast.ClassDef, ast.FunctionDef))]
            return sorted(exported, key=lambda name: order.index(name) if name in order else len(order))
    raise ValueError('module without __all__')


def page(title, body):
    return f'<!DOCTYPE html>\n<html><head><meta charset="utf-8"><title>{html.escape(title)}</title></head>\n<body>\n{body}\n</body></html>\n'


def index_page(exports):
    groups = {}
    for module, group in MODULES:
        groups.setdefault(group, []).append(module)
    body = [
        '<h1>Albumentations</h1>',
        '<!-- README -->',
        '<h2 id="api-reference">API reference</h2>',
        '<p>Every class and function below is available as <code>A.Name</code> after '
        '<code>import albumentations as A</code>. The <code>functional</code> modules behind the transforms '
        'aren&#8217;t exported and aren&#8217;t documented here.</p>',
    ]
    for group, group_modules in groups.items():
        body.append(f'<h3>{html.escape(group)}</h3>')
        body.append('<ul>')
        for module in group_modules:
            links = ', '.join(f'<a href="{module}.html#{name}"><code>{name}</code></a>' for name in exports[module])
            body.append(f'<li><a href="{module}.html">{dotted(module)}</a>: {links}</li>')
        body.append('</ul>')
    return page('Albumentations', '\n'.join(body))


def dotted(module):
    return 'albumentations.' + module.replace('/', '.')


class Renderer:
    def __init__(self, package, names):
        self.package = package
        self.names = names

    def module_page(self, module, group, exported):
        self.module = module
        self.directory = os.path.dirname(module)
        tree = self.package.tree(module)
        # The scraper's entries filter types the entries after the group
        body = [f'<h1 data-type="{html.escape(group)}">{dotted(module)}</h1>']
        docstring = ast.get_docstring(tree)
        if docstring:
            body.append(self.docstring(docstring))
        for name in exported:
            node = self.package.definition(module, name)
            body.append(f'<h2 id="{name}">A.{name}</h2>')
            if isinstance(node, ast.ClassDef):
                body.append(self.class_body(module, node))
            else:
                body.append(self.function_body(node, f'albumentations.{name}'))
        return page(dotted(module), '\n'.join(body))

    def class_body(self, module, node):
        init = self.find_init(node)
        signature = f'class albumentations.{node.name}' + format_arguments(init.args if init else None)
        parts = [code_block(signature, 'signature')]
        bases = [ast.unparse(base) for base in node.bases if ast.unparse(base) not in ('Generic', 'ABC')]
        if bases:
            parts.append('<p class="_bases">Bases: ' + ', '.join(self.link_name(base) for base in bases) + '</p>')
        docstring = ast.get_docstring(node)
        if docstring:
            parts.append(self.docstring(docstring))
        if module in WITH_METHODS:
            for child in node.body:
                if not isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    continue
                if child.name.startswith('_') and child.name != '__call__':
                    continue
                if child.name == '__init__' or not ast.get_docstring(child):
                    continue
                if any(ast.unparse(d) in ('property', 'cached_property') or ast.unparse(d).endswith('.setter') for d in child.decorator_list):
                    continue
                anchor = f'{node.name}.{child.name}'
                parts.append(f'<h3 id="{anchor}">{node.name}.{child.name}()</h3>')
                parts.append(self.function_body(child, child.name, method=True))
        return '\n'.join(parts)

    def function_body(self, node, name, method=False):
        decorators = [ast.unparse(d) for d in node.decorator_list]
        prefix = '@staticmethod\n' if 'staticmethod' in decorators else '@classmethod\n' if 'classmethod' in decorators else ''
        signature = prefix + name + format_arguments(node.args, skip_self=method)
        if node.returns:
            signature += ' -> ' + ast.unparse(node.returns)
        parts = [code_block(signature, 'signature')]
        docstring = ast.get_docstring(node)
        if docstring:
            parts.append(self.docstring(docstring))
        return '\n'.join(parts)

    def find_init(self, node, module=None):
        module = module or self.module
        for child in node.body:
            if isinstance(child, ast.FunctionDef) and child.name == '__init__':
                return child
        for base in node.bases:
            name = ast.unparse(base).split('[')[0]
            # The module the base class is defined in
            for candidate in (module, *(m for m, _ in MODULES)):
                definition = self.package.definition(candidate, name)
                if isinstance(definition, ast.ClassDef) and definition is not node:
                    found = self.find_init(definition, self.defining_module(candidate, name))
                    if found:
                        return found
                    break
        return None

    def defining_module(self, module, name):
        tree = self.package.tree(module)
        for node in tree.body:
            if isinstance(node, ast.ImportFrom) and node.level and any(alias.name == name for alias in node.names):
                base = module.split('/')[:-node.level]
                return self.defining_module('/'.join(base + (node.module.split('.') if node.module else [])), name)
        return module

    def link_name(self, name):
        if name in self.names:
            href = os.path.relpath(self.names[name], self.directory)
            return f'<a href="{href}"><code>{html.escape(name)}</code></a>'
        return f'<code>{html.escape(name)}</code>'

    def docstring(self, text):
        text = text.expandtabs(4)
        lines = text.split('\n')
        sections = [(None, [])]
        for line in lines:
            match = SECTION.match(line)
            if match and (match.group(1) in ARGS | DEFINITIONS | FACTS | PROSE or FORMULAS.match(match.group(1))):
                sections.append((match.group(1), []))
            else:
                sections[-1][1].append(line)

        parts = []
        facts = []
        for title, body in sections:
            body = dedent(body)
            if title in FACTS:
                facts.append(f'<tr><th>{html.escape(title)}</th><td>{inline(" ".join(l.strip() for l in body if l.strip()))}</td></tr>')
                continue
            if facts:
                parts.append('<table class="_facts">' + ''.join(facts) + '</table>')
                facts = []
            if title is None:
                parts.append(render_blocks(body))
                continue
            parts.append(f'<h4>{html.escape(title)}</h4>')
            if title in ARGS:
                parts.append(render_arguments(body))
            elif title in DEFINITIONS:
                parts.append(render_definitions(body))
            elif FORMULAS.match(title):
                parts.append(code_block('\n'.join(body).strip('\n'), None, language=None))
            else:
                parts.append(render_blocks(body))
        if facts:
            parts.append('<table class="_facts">' + ''.join(facts) + '</table>')
        return '\n'.join(part for part in parts if part)


def format_arguments(args, skip_self=True):
    if args is None:
        return '()'
    items = []
    positional = args.posonlyargs + args.args
    defaults = [None] * (len(positional) - len(args.defaults)) + args.defaults
    for index, (arg, default) in enumerate(zip(positional, defaults)):
        if index == 0 and skip_self and arg.arg in ('self', 'cls'):
            continue
        items.append(format_argument(arg, default))
        if args.posonlyargs and arg is args.posonlyargs[-1]:
            items.append('/')
    if args.vararg:
        items.append('*' + format_argument(args.vararg, None))
    elif args.kwonlyargs:
        items.append('*')
    for arg, default in zip(args.kwonlyargs, args.kw_defaults):
        items.append(format_argument(arg, default))
    if args.kwarg:
        items.append('**' + format_argument(args.kwarg, None))

    single = '(' + ', '.join(items) + ')'
    if len(single) <= SIGNATURE_WIDTH:
        return single
    return '(\n' + ''.join(f'    {item},\n' for item in items) + ')'


def format_argument(arg, default):
    text = arg.arg
    if arg.annotation:
        text += ': ' + ast.unparse(arg.annotation)
        if default is not None:
            text += ' = ' + ast.unparse(default)
    elif default is not None:
        text += '=' + ast.unparse(default)
    return text


def code_block(code, css_class, language='python'):
    attributes = f' data-language="{language}"' if language else ''
    if css_class:
        attributes += f' class="{css_class}"'
    return f'<pre{attributes}>{html.escape(code, quote=False)}</pre>'


def dedent(lines):
    while lines and not lines[0].strip():
        lines = lines[1:]
    while lines and not lines[-1].strip():
        lines = lines[:-1]
    return textwrap.dedent('\n'.join(lines)).split('\n') if lines else []


def indentation(line):
    return len(line) - len(line.lstrip(' '))


def inline(text):
    text = html.escape(text, quote=False)
    code = []

    def keep(match):
        code.append(match.group(1))
        return f'\0{len(code) - 1}\0'

    text = re.sub(r'``(.+?)``', keep, text)
    text = re.sub(r'(?<![\w`])`([^`]+?)`(?!\w)', keep, text)
    text = URL.sub(lambda m: f'<a href="{m.group(1)}">{m.group(1)}</a>', text)
    text = re.sub(r'\*\*(\S(?:.*?\S)?)\*\*', r'<strong>\1</strong>', text)
    text = re.sub(r'(?<![\w*])\*(\S(?:[^*]*?\S)?)\*(?![\w*])', r'<em>\1</em>', text)
    return re.sub(r'\0(\d+)\0', lambda m: f'<code>{code[int(m.group(1))]}</code>', text)


def render_blocks(lines):
    """Renders paragraphs, lists, doctests and indented blocks."""
    lines = dedent(lines)
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
        elif line.startswith('>>>'):
            block = []
            while i < len(lines) and lines[i].strip():
                block.append(lines[i])
                i += 1
            out.append(doctest(block))
        elif LIST_ITEM.match(line):
            ordered = line[0].isdigit()
            items = []
            while i < len(lines) and LIST_ITEM.match(lines[i]) and lines[i][0].isdigit() == ordered:
                item = [LIST_ITEM.sub('', lines[i], count=1)]
                i += 1
                while i < len(lines):
                    if lines[i].strip() and indentation(lines[i]) == 0:
                        break
                    if not lines[i].strip():
                        following = next((l for l in lines[i:] if l.strip()), None)
                        if following is None or indentation(following) == 0:
                            break
                    item.append(lines[i])
                    i += 1
                items.append(render_item(item))
                while i < len(lines) and not lines[i].strip():
                    i += 1
            tag = 'ol' if ordered else 'ul'
            out.append(f'<{tag}>' + ''.join(f'<li>{item}</li>' for item in items) + f'</{tag}>')
        elif indentation(line) > 0:
            block = []
            while i < len(lines) and (not lines[i].strip() or indentation(lines[i]) > 0):
                block.append(lines[i])
                i += 1
            block = dedent(block)
            if looks_like_code(block):
                out.append(code_block('\n'.join(block), None))
            else:
                out.append(render_blocks(block))
        else:
            paragraph = []
            while i < len(lines) and lines[i].strip() and indentation(lines[i]) == 0 and not lines[i].startswith('>>>'):
                if paragraph and LIST_ITEM.match(lines[i]):
                    break
                if paragraph and is_label(lines, i):
                    break
                paragraph.append(lines[i].strip())
                i += 1
            if len(paragraph) == 1 and paragraph[0].endswith('::'):
                paragraph[0] = paragraph[0][:-1]
            if len(paragraph) == 1 and is_label(lines, i - 1) and len(paragraph[0]) <= 40 and not looks_like_code(dedent(indented_block(lines, i)[0])):
                # "If tuple:" followed by an indented description
                block, i = indented_block(lines, i)
                out.append(f'<dl><dt>{inline(paragraph[0])}</dt><dd>{render_blocks(block)}</dd></dl>')
                continue
            out.append('<p>' + inline(' '.join(paragraph)) + '</p>')
    return '\n'.join(out)


def is_label(lines, i):
    """Whether lines[i] ends with a colon and introduces an indented block."""
    if not lines[i].rstrip().endswith(':') or lines[i].rstrip().endswith('::'):
        return False
    following = next((l for l in lines[i + 1:] if l.strip()), None)
    return following is not None and indentation(following) > 0 and indentation(lines[i]) == 0


def indented_block(lines, i):
    block = []
    while i < len(lines) and (not lines[i].strip() or indentation(lines[i]) > 0):
        block.append(lines[i])
        i += 1
    return block, i


def render_item(lines):
    # The continuation lines are indented relative to the marker
    rendered = description(lines[0], lines[1:])
    if rendered.startswith('<p>') and rendered.count('<p>') == 1 and rendered.endswith('</p>'):
        return rendered[3:-4]
    return rendered


def looks_like_code(lines):
    code = [l for l in lines if l.strip()]
    if not code:
        return False
    if all(l.startswith(('>>>', '...')) for l in code if indentation(l) == 0):
        return False
    pattern = re.compile(r'^\s*(import |from \w+ import|[\w.\[\]]+\s*=[^=]|[\w.]+\(.*\)\s*$|#|\)|\]|\})')
    return sum(1 for l in code if pattern.match(l)) * 2 >= len(code)


def doctest(lines):
    prompted = [l for l in lines if l.startswith(('>>>', '...'))]
    if len(prompted) == len(lines):
        # No output: drop the prompts so that the code can be copied
        code = '\n'.join(re.sub(r'\A(>>>|\.\.\.) ?', '', l) for l in lines)
    else:
        code = '\n'.join(lines)
    return code_block(code.strip('\n'), None)


def split_definition(line):
    """Splits `name (type): description` and returns (name, type, description), or None."""
    match = re.match(r'\A(\*{0,2}[A-Za-z_][\w.]*)\s*', line)
    if not match:
        return None
    name, rest = match.group(1), line[match.end():]
    type_ = None
    if rest.startswith('('):
        depth = 0
        for index, char in enumerate(rest):
            depth += {'(': 1, ')': -1}.get(char, 0)
            if depth == 0:
                break
        else:
            return None
        type_, rest = rest[1:index], rest[index + 1:].lstrip()
    if not rest.startswith(':') or rest.startswith('::'):
        return None
    return name, type_, rest[1:].strip()


def collect_definitions(lines, parse):
    """Groups the lines into (head, description lines) by unindented lines that parse."""
    entries = []
    preface = []
    for line in lines:
        head = parse(line) if line.strip() and indentation(line) == 0 else None
        if head:
            entries.append((head, []))
        elif entries:
            entries[-1][1].append(line)
        else:
            preface.append(line)
    return preface, entries


def description(first, rest):
    rest = dedent(rest)
    if rest and rest[0].strip() and indentation(rest[0]) == 0 and not LIST_ITEM.match(rest[0]) and not rest[0].startswith('>>>'):
        lines = [first] + rest
    else:
        lines = [first] + ['    ' + l if l.strip() else l for l in rest] if first else rest
    return render_blocks(lines)


def render_arguments(lines):
    preface, entries = collect_definitions(dedent(lines), split_definition)
    if not entries:
        return render_blocks(lines)
    out = [render_blocks(preface)] if any(l.strip() for l in preface) else []
    out.append('<dl class="_params">')
    for (name, type_, first), rest in entries:
        term = f'<code>{html.escape(name)}</code>'
        if type_:
            term += f' (<em>{html.escape(type_)}</em>)'
        out.append(f'<dt>{term}</dt><dd>{description(first, rest)}</dd>')
    out.append('</dl>')
    return '\n'.join(out)


def split_type(line):
    # "np.ndarray: The image.", "tuple[int, int]: ...", "ValueError: If ..."
    match = re.match(r'\A([\w.]+(?:\[[^\]]*(?:\[[^\]]*\][^\]]*)*\])?(?:\s*\|\s*[\w.]+(?:\[[^\]]*(?:\[[^\]]*\][^\]]*)*\])?)*)\s*:\s+(.*)\Z', line)
    if match and not match.group(1)[0].islower() or match and re.search(r'[\[.|]|\A(int|float|str|bool|dict|list|tuple|bytes|None|np|object)\b', match.group(1)):
        return match.group(1), match.group(2)
    return None


def render_definitions(lines):
    preface, entries = collect_definitions(dedent(lines), split_type)
    if not entries or any(l.strip() for l in preface):
        return render_blocks(lines)
    out = ['<dl class="_params">']
    for (type_, first), rest in entries:
        out.append(f'<dt><em>{html.escape(type_)}</em></dt><dd>{description(first, rest)}</dd>')
    out.append('</dl>')
    return '\n'.join(out)


if __name__ == '__main__':
    main(*sys.argv[1:])
