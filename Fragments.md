elaboration

<html>
    <body>
        <div hx-target="this">
          #fragment archive-ui
            #if contact.archived
            <button hx-patch="/contacts/${contact.id}/unarchive">Unarchive</button>
            #else
            <button hx-delete="/contacts/${contact.id}">Archive</button>
            #end
          #end
        </div>
        <h3>Contact</h3>
        <p>${contact.email}</p>
    </body>
</html>

all

Contact c = getContact();
ChillTemplates.render("/contacts/detail.html", "contact", c);

frag

Contact c = getContact();
ChillTemplates.render("/contacts/detail.html#archive-ui", "contact", c);


solutions


fragments can leverage conditionals

maybe call a template sub externally

<:sub header>
  <header>
    <nav>
      blah blabh
    </nav>
  </header>
</:>

nope because I want these inline, just tagged as frags

Fragments

A fragment works by labeling a subset of a crotmp file, so that optionally it can be singled out by the template function. To get a fragment, pass its name to the `template` command  `fragment => 'name'`. If no fragment name is specified, then the fragment tags are ignored and the fragment contents are rendered as normal. Multiple fragments can be specified in a crotmp file by using unique names, only one is rendered. They may not be nested.

--- page.crotmp
<html>
    <body>
        <div hx-target="this">
          <:fragment archive-ui>
            <?.archived>
            <button hx-patch="contacts/<.id>/unarchive">Unarchive</button>
            <!>
            <button hx-delete="/contacts/<.id>">Archive</button>
            </!>
          </:>
        </div>
        <h3>Contact</h3>
        <p><.email></p>
    </body>
</html>
---

my $contact = {
    archived => True,
    id => 007,
    email => 'me@me.com',
};

template 'page.crotmp', $contact;

<html>
    <body>
        <div hx-target="this">
            <button hx-patch="/contacts/007/unarchive">Unarchive</button>
        </div>
        <h3>Contact</h3>
        <p><.email></p>
    </body>
</html>

template 'page.crotmp', $contact, fragment => 'archive-ui';

<button hx-patch="/contacts/007/unarchive">Unarchive</button>


---

hook this
my %template-exports := $ast.compile()<exports>;
in Template/Library.rakumod
ok

go down into Parser.rakumod


- [x] sub by another name
- [ ] sub that 
  - takes main topic
  - called by self
- [ ] like a sub
  - one of repository exports
  - can in fact be called standalone
  - unique name in repo


document
add to comma syntax hl


---

touch files search 'macro'
- [x] AST.rakumod
- [x] ASTBuilder.rakumod
- [ ] Template/Library.rakumod
- [ ] Parser.rakumod
- [ ] test-template-library.crotmp
- [ ] library.rakutest
- [ ] template-basic.rakutest
- [ ] template-parts.rakutest
- [ ] template-router-integration.rakutest
- [ ] template-use.rakutest
- [ ] common.crotmp
- [ ] macro-1.crotmp
- [ ] macro-2.crotmp
- [ ] parts-layout.crotmp
- [ ] transitive-use.crotmp

- [x] Repository.rakumod


#iamerejh
class Cro::WebApp::Template::Compiled in Repository
and
 Cro::WebApp::Template::Compiled.new(|$ast.compile, in Repository

maybe want a class Fragmenter that mangles the fagment name and calls the fragment as an export


clean up library.rakutest

===

how about the way to run it is

template-fragment 'templates/product.crotmp', :$fragment, $topic;

this makes a literal.crotmp

<:use Some::Library>
<§frag-test()>

syntax §frag is used for FragmentApplication







