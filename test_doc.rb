require_relative "doc"
require "test/unit"
 
class DocTest < Test::Unit::TestCase
 
  # copied from https://github.com/thomsbg/convert-rich-text/blob/master/test/test.js
  TESTS = [

    {
      desc: 'No formats',
      delta: { ops: [
        {insert: "Hello world\n"}
      ]},
      expected:
        '<div>Hello world</div>'
    },

    {
      desc: 'Simple inline tags',
      delta: { ops: [
        {insert: 'Hello, '},
        {insert: 'World!', attributes: {bold: true}},
        {insert: "\n"}
      ]},
      expected:
        '<div>Hello, <b>World!</b></div>'
    },

    {
      desc: 'Line formats, embeds, and attributes',
      delta: { ops: [
        {insert: "Hello, World!\nThis is a second line.", attributes: {bold: true}},
        {insert: "\n", attributes: {firstheader: true}},
        {insert: 'This is a demo of convert-rich-text '},
        {insert: 1, attributes: {
          image: 'http://i.imgur.com/2ockv.gif'
        }},
        {insert: " "},
        {insert: 'Google', attributes: {link: 'https://www.google.com'}},
        {insert: "\n"}
      ]},
      expected:
        '<div><b>Hello, World!</b></div>' +
        '<h1><b>This is a second line.</b></h1>' +
        '<div>This is a demo of convert-rich-text ' +
        '<img src="http://i.imgur.com/2ockv.gif"> ' +
        '<a href="https://www.google.com">Google</a></div>'
    },

    {
      desc: 'classes and styles',
      delta: { ops: [
        {insert: 'Hello world', attributes: { color: 'red', user: 1234 }},
        {insert: "\n"}
      ]},
      expected:
        '<div><span style="color: red; " class="user-1234">Hello world</span></div>'
    },

    {
      desc: 'attribute with implicit span tag',
      delta: { ops: [
        {insert: 'hello world', attributes: { class_name: 'greeting' }},
        {insert: "\n"}
      ]},
      expected:
        '<div><span class="greeting">hello world</span></div>'
    },

    {
      desc: 'Lists',
      delta: { ops: [
        {insert: 'Consecutive list elements'},
        {insert: "\n", attributes: {list: true}},
        {insert: 'Should create a parent tag'},
        {insert: "\n", attributes: {list: true}},
        {insert: 'Consecutive bullet elements'},
        {insert: "\n", attributes: {bullet: true}},
        {insert: 'Should create a parent tag'},
        {insert: "\n", attributes: {bullet: true}}
      ]},
      expected:
        '<ol><li>Consecutive list elements</li>' +
        '<li>Should create a parent tag</li></ol>' +
        '<ul><li>Consecutive bullet elements</li>' +
        '<li>Should create a parent tag</li></ul>'
    },

    {
      desc: 'Links',
      delta: { ops: [
        {attributes:{bold:true},insert:'hello'},
        {insert:' '},
        {attributes:{link:'http://vox.com'},insert:'world'},
        {insert:" this works...?\n"}
      ]},
      expected:
        '<div><b>hello</b> <a href="http://vox.com">world</a> this works...?</div>'
    },

    {
      desc: 'Link inside list',
      delta: { ops: [
        {insert: 'Some text '},
        {insert: 'a link', attributes: {link: 'http://vox.com'}},
        {insert: ' more text'},
        {insert: "\n", attributes: {list: true}}
      ]},
      expected:
        '<ol><li>Some text <a href="http://vox.com">a link</a> more text</li></ol>'
    },

    {
      desc: 'Modify parent',
      delta: { ops: [
        {insert: 'hello world', attributes: { parent: 'article' } },
        {insert: "\n", attributes: { firstheader: true } }
      ]},
      expected:
        '<h1>hello world</h1>'
    },

    {
      desc: 'Custom formats',
      delta: { ops: [
        {insert: 'Hello World!', attributes: {reverse: true}},
        {insert: "\n"},
        {insert: 'Foo Bar Baz', attributes: {bold: true, repeat: 3}},
        {insert: "\n", attributes: { data: {foo: 'bar'}}}
      ]},
      expected:
        '<div>!dlroW olleH</div>' +
        '<div data-foo="bar"><b>Foo Bar Baz</b><b>Foo Bar Baz</b><b>Foo Bar Baz</b></div>'
    },
    {
      desc: 'Change default blockTag',
      delta: { ops: [{insert: 'Hello world'}]},
      opts: { block_tag: 'p' },
      expected: '<p>Hello world</p>'
    },
    {
      desc: 'Line formats with no contents',
      delta: { ops: [{insert: "\n", attributes: {firstheader: true} }] },
      expected: '<h1></h1>'
    }
  ]

  ANTHEM_TESTS = [
    {
      msg: 'empty delta into empty string',
      delta: { ops: [] },
      html: ''
    },
    {
      msg: 'plain insert into paragraph',
      delta: { ops: [ {insert: 'hello world'} ] },
      html: '<p>hello world</p>'
    },
    {
      msg: 'multiple lines into paragraphs',
      delta: { ops: [ {insert: "hello\nworld"} ] },
      html: '<p>hello</p><p>world</p>'
    },
    {
      msg: 'italic into em',
      delta: { ops: [ {insert: 'abc', attributes: { italic: true }} ] },
      html: '<p><em>abc</em></p>'
    },
    {
      msg: 'bullet into ul',
      delta: { ops: [
        { insert: 'hello' },
        { insert: "\n", attributes: {bullet: true} },
        { insert: 'world' },
        { insert: "\n", attributes: {bullet: true} }
      ]},
      html: '<ul><li>hello</li><li>world</li></ul>'
    },
    {
      msg: 'firstheader into h1',
      delta: { ops: [
        { insert: 'hello world' },
        { insert: "\n", attributes: {firstheader: true} }
      ]},
      html: '<h1>hello world</h1>'
    },
    {
      msg: 'blockquote into blockquote',
      delta: { ops: [
        { insert: 'hello world' },
        { insert: "\n", attributes: {blockquote: true} }
      ]},
      html: '<blockquote><p>hello world</p></blockquote>'
    },
    {
      msg: 'multiple inline formats link into link',
      delta: { ops: [
          { insert: 'hello ' },
          { insert: 'world', attributes: {link: 'http://vox.com'} },
          { insert: ' ' },
          { insert: 'yay', attributes: {bold: true} }
        ]},
      html: '<p>hello <a href="http://vox.com">world</a> <strong>yay</strong></p>'
    },
    {
      msg: 'image into chorus asset markup',
      delta: { ops: [
          { insert: "hello world\n" },
          { insert: 1, attributes: {image: { id: 1234, src: 'http://i.imgur.com/2ockv.gif', caption: '<em>Clickity-Clack</em>'}} }
        ]},
      html:
        '<p>hello world</p>' +
        '<div data-chorus-asset-id="1234"><img src="http://i.imgur.com/2ockv.gif"><div class="caption"><em>Clickity-Clack</em></div></div>'
    },
    {
      msg: 'links inside list items',
      delta: { ops: [
          { insert: 'hello ' },
          { insert: 'world', attributes: {link: 'http://vox.com'} },
          { insert: ' yay' },
          { insert: "\n", attributes: {list: true} }
        ]},
      html:
        '<ol><li>hello <a href="http://vox.com">world</a> yay</li></ol>'
    },
    {
      msg: 'big fat complex test',
      delta:
        { ops: [
          { insert: 'This is gold, Mr. Bond' },
          { insert: "\n", attributes: {firstheader: true} },
          { insert: 1, attributes: {image: { id: 9, src: 'http://www.independent.co.uk/incoming/article8435194.ece/alternates/w620/Goldfinger.jpg', caption: '<em>This cannot end well.</em>'}} },
          { insert: "\n" },
          { insert: 'All my life, I\'ve been in love with its colour, ' },
          { insert: "its brilliance, its divine heaviness. ", attributes: {italic:true} },
          { insert: 'I welcome any enterprise that will increase my stock, which is ' },
          { insert: "considerable.", attributes: {bold:true} },
          { insert: "\n" },
          { insert: "I think you\'ve made your point. Thank you for the demonstration." },
          { insert: "\n", attributes: {blockquote:true} },
          { insert: "Choose your next witticism carefully,", attributes: { link: 'http://www.script-o-rama.com/movie_scripts/g/goldfinger-script-transcript-james-bond.html'} },
          { insert: "\n", attributes: {list:true} },
          { insert: "Mr. Bond", attributes: {bold:true} },
          { insert: "\n", attributes: {list:true} },
          { insert: "It may be " },
          { insert: "your last.", attributes: {italic:true} },
          { insert: "\n", attributes: {list:true} },
          { insert: "The purpose of our two encounters is now very clear to me. I do not intend to be distracted by another.\n" },
          { insert: "Good night, Mr Bond." },
          { insert: "\n", attributes: {secondheader:true} },
          { insert: "Do you expect me to talk?" },
          { insert: "\n", attributes: {blockquote:true} },
          { insert: "No, Mr Bond!\nI expect you to die!" },
          { insert: "\n", attributes: {firstheader:true} },
          { insert: 1, attributes: {image: { id: 10, src: 'http://www.filmchronicles.com/wp-content/uploads/2012/10/Goldfinger065.jpg', caption: 'I knew this was going to go badly.'}} }
        ]},
      html: '<h1>This is gold, Mr. Bond</h1><div data-chorus-asset-id="9"><img src="http://www.independent.co.uk/incoming/article8435194.ece/alternates/w620/Goldfinger.jpg"><div class="caption"><em>This cannot end well.</em></div></div><p>All my life, I\'ve been in love with its colour, <em>its brilliance, its divine heaviness. </em>I welcome any enterprise that will increase my stock, which is <strong>considerable.</strong></p><blockquote><p>I think you\'ve made your point. Thank you for the demonstration.</p></blockquote><ol><li><a href="http://www.script-o-rama.com/movie_scripts/g/goldfinger-script-transcript-james-bond.html">Choose your next witticism carefully,</a></li><li><strong>Mr. Bond</strong></li><li>It may be <em>your last.</em></li></ol><p>The purpose of our two encounters is now very clear to me. I do not intend to be distracted by another.</p><h2>Good night, Mr Bond.</h2><blockquote><p>Do you expect me to talk?</p></blockquote><p>No, Mr Bond!</p><h1>I expect you to die!</h1><div data-chorus-asset-id="10"><img src="http://www.filmchronicles.com/wp-content/uploads/2012/10/Goldfinger065.jpg"><div class="caption">I knew this was going to go badly.</div></div>'
    }
  ]

  FORMATS = {
    bold: { tag: 'b' },
    color: { style: 'color' },
    user: { class: 'user-' },
    firstheader: { type: 'line', tag: 'h1' },
    image: { type: 'embed', tag: 'img', attribute: 'src' },
    link: { tag: 'a', attribute: 'href' },
    class_name: { attribute: 'class' },
    bullet: { type: 'line', tag: 'li', parent_tag: 'ul' },
    list: { type: 'line', tag: 'li', parent_tag: 'ol' },
    parent: {
      type: "embed",
      add: lambda do |node, value|
        if node.text?
          Nokogiri::XML::Node.new(value, node) << node
        else
          node.parent.name = value
        end

        node
      end
    },

    reverse: { add: lambda do |node, value|
        node.content = node.text.reverse
        node
      end
    },

    repeat: { add: lambda do |node, value|
        (value.to_i - 1).times { (node.parent << node.clone) }
        node
      end
    },

    data: { type: 'line', add: lambda do |node, value|
        value.each { |k, v| node["data-#{k}"] = v }
        node
      end
    }
  }

  ANTHEM_FORMATS = FORMATS.merge({
    bold: { tag: 'strong' },
    italic: { tag: 'em' },
    strike: { tag: 's' },
    link: { tag: 'a', attribute: 'href' },
    firstheader: { type: 'line', tag: 'h1' },
    secondheader: { type: 'line', tag: 'h2' },
    thirdheader: { type: 'line', tag: 'h3' },
    bullet: { type: 'line', parent_tag: 'ul', tag: 'li' },
    list: { type: 'line', parent_tag: 'ol', tag: 'li' },
    blockquote: { type: 'line', parent_tag: 'blockquote' },
    image: {
      type: 'embed', # is type necessary
      add: lambda do |node, value|
        if node.text?
          Nokogiri::XML::Node.new('div', node) << node
        else
          node.parent.name = 'div'
        end

        # clear content
        node.content = ''
        node.parent['data-chorus-asset-id'] = value[:id]
        img = Nokogiri::XML::Node.new('img', node.parent)
        img['src'] = value[:src]
        node.parent << img

        if value[:caption]
          caption = Nokogiri::XML::Node.new('div', node.parent)
          caption['class'] = 'caption'
          caption.inner_html = value[:caption]
          node.parent << caption
        end

        node
      end
    }
    #pullquote: require('lib/quill/formats/pullquote').public,
    #oembed: require('lib/quill/formats/oembed').public,
    #video: require('lib/quill/formats/video').public
  })

  # basic tests
  TESTS.each do |t|
    test t[:desc] do
      result = Doc.convert(t[:delta], FORMATS, t[:opts] || {})
      assert_equal t[:expected], result
    end
  end

  # anthem tests
  ANTHEM_TESTS.each do |t|
    test t[:msg] do
      opts = { block_tag: 'p' }
      result = Doc.convert(t[:delta], ANTHEM_FORMATS, opts)
      assert_equal t[:html], result
    end
  end

end