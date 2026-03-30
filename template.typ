// autobook base template — print-ready book layout for children's historical fiction
#let book(
  title: "Untitled",
  author: "Unknown",
  date: none,
  paper: "us-trade",
  font-body: "Libertinus Serif",
  font-heading: "Libertinus Serif",
  font-size: 11.5pt,
  body,
) = {
  set document(title: title, author: author)
  set page(
    paper: paper,
    margin: (top: 1.0in, bottom: 1.0in, inside: 1.0in, outside: 0.75in),
    // Running header: chapter title on recto, book title on verso
    header: context {
      let current = here().page()
      let on-chapter = query(heading.where(level: 1)).any(h => h.location().page() == current)
      if current > 5 and not on-chapter {
        if calc.odd(current) {
          // Recto: show current chapter title
          let chapters = query(heading.where(level: 1)).filter(h => h.location().page() <= current)
          if chapters.len() > 0 {
            align(right, text(size: 9pt, style: "italic")[#chapters.last().body])
          }
        } else {
          // Verso: show book title
          align(left, text(size: 9pt, style: "italic")[#title])
        }
      }
    },
    footer: context {
      let current = here().page()
      let on-chapter = query(heading.where(level: 1)).any(h => h.location().page() == current)
      if current > 5 and not on-chapter {
        align(center, text(size: 9pt)[#current])
      }
    },
  )
  set text(font: font-body, size: font-size, lang: "es")
  set par(justify: true, leading: 1.2em, first-line-indent: 1em)

  show heading.where(level: 1): it => {
    pagebreak(weak: true, to: "odd")
    v(2in)
    set text(font: font-heading, weight: "bold")
    block[#text(size: 22pt)[#it.body]]
    v(1.2em)
  }
  show heading.where(level: 2): it => {
    v(1.5em)
    set text(font: font-heading, size: 14pt, weight: "bold")
    block(it.body)
    v(0.8em)
  }
  show heading: it => { it; par(text(size: 0pt, "")) }

  // Half-title
  page(header: none, footer: none, margin: (top: 3.5in, bottom: 2in))[
    #align(center)[#text(font: font-heading, size: 18pt, style: "italic")[#title]]
  ]
  page(header: none, footer: none)[]
  // Full title
  page(header: none, footer: none, margin: (top: 3in, bottom: 2in))[
    #align(center)[
      #text(font: font-heading, size: 34pt, weight: "bold")[#title]
      #v(0.5em)
      #line(length: 20%, stroke: 0.5pt)
      #v(1.5em)
      #text(size: 14pt)[#author]
      #if date != none { v(1em); text(size: 11pt, style: "italic")[#date] }
    ]
  ]
  // Copyright
  page(header: none, footer: none)[
    #v(1fr)
    #set text(size: 8pt)
    Copyright © #if date != none { date } else { "2026" } #author \
    Todos los derechos reservados. \
    #v(0.5em)
    Compuesto en #font-body. \
    Formato: 15.2 × 22.9 cm (6 × 9 pulg.)
  ]
  // TOC
  page(header: none, footer: none)[
    #v(1.5in)
    #text(font: font-heading, size: 18pt, weight: "bold")[Índice]
    #v(1em)
    #outline(indent: 1.5em, depth: 1, title: none)
  ]
  pagebreak(to: "odd")
  body
  // Colophon
  pagebreak(to: "odd")
  page(header: none, footer: none)[
    #v(1fr)
    #align(center)[
      #set text(size: 8pt, style: "italic")
      Este libro fue compuesto en #font-body \
      e impreso en formato de 15.2 × 22.9 cm. \
      #v(0.5em)
      Λ
    ]
  ]
}
