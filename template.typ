// autobook base template — print-ready book layout
// The agent creates book.typ which imports this template.
//
// Usage in book.typ:
//   #import "template.typ": book
//   #show: book.with(
//     title: "My Book Title",
//     author: "Author Name",
//     date: "2026",
//   )
//   = Chapter One
//   Content here...

#let book(
  title: "Untitled",
  author: "Unknown",
  date: none,
  paper: "us-trade",
  font-body: "Libertinus Serif",
  font-heading: "Libertinus Serif",
  font-size: 11pt,
  body,
) = {

  // Document metadata
  set document(title: title, author: author)

  // Page geometry — US trade paperback (6" x 9") by default
  set page(
    paper: paper,
    margin: (
      top: 0.9in,
      bottom: 1in,
      inside: 0.85in,
      outside: 0.7in,
    ),
    // Running header with page number, suppressed on chapter openings
    header: context {
      let current = here().page()
      if current > 3 {
        if calc.odd(current) {
          align(right, text(size: 9pt, style: "italic")[#title])
        } else {
          align(left, text(size: 9pt, style: "italic")[#author])
        }
      }
    },
    footer: context {
      let current = here().page()
      if current > 2 {
        align(center, text(size: 9pt)[#current])
      }
    },
  )

  // Typography
  set text(font: font-body, size: font-size, lang: "en")
  set par(justify: true, leading: 0.65em, first-line-indent: 1.5em)

  // Heading styles
  // Level 1 = Chapter headings
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(2in)
    set text(font: font-heading, size: 22pt, weight: "bold")
    block(it.body)
    v(1.2em)
  }

  // Level 2 = Section breaks within chapters
  show heading.where(level: 2): it => {
    v(1.5em)
    set text(font: font-heading, size: 14pt, weight: "bold")
    block(it.body)
    v(0.8em)
  }

  // Remove first-line indent after headings
  show heading: it => {
    it
    par(text(size: 0pt, ""))
  }

  // ── Title page ──
  page(header: none, footer: none, margin: (top: 3in, bottom: 2in))[
    #align(center)[
      #text(font: font-heading, size: 28pt, weight: "bold")[#title]
      #v(2em)
      #text(size: 14pt)[#author]
      #if date != none {
        v(1em)
        text(size: 11pt, style: "italic")[#date]
      }
    ]
  ]

  // ── Blank verso (back of title page) ──
  page(header: none, footer: none)[]

  // ── Table of contents ──
  page(header: none)[
    #v(1.5in)
    #text(font: font-heading, size: 18pt, weight: "bold")[Contents]
    #v(1em)
    #outline(indent: 1.5em, depth: 1, title: none)
  ]

  // ── Body ──
  pagebreak()
  body
}
