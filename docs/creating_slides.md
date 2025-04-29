---
title: Creating Slides
---

# Creating Slides with MdSlides

MdSlides allows you to create presentations using simple Markdown syntax. This document covers the basic structure and formatting options available using MdSlides' built-in features, focusing on the Markdown source itself rather than advanced Reveal.js configurations or plugins.

---

## Basic Slide Separation (Horizontal Slides)

The fundamental way to separate slides is horizontally. Each new slide begins after a line containing exactly three dashes (`---`).

**Example:**

```markdown
# Slide 1 Title

This is the content of the first slide.

---

# Slide 2 Title

This is the content of the second slide.
```

---

## Vertical Slides

You can also create vertical slides, which appear stacked below a primary horizontal slide. Use a line containing `-v-` (surrounded by optional whitespace) to separate vertical slides.

**Example:**

```markdown
# Main Horizontal Slide

Content for the top slide.

-v-

## First Vertical Slide

Content for the first slide down.

-v-

## Second Vertical Slide

Content for the second slide down.
```

---

## Adding Speaker Notes

You can add speaker notes, which are typically visible only to the presenter, by starting a line with `Note:` or `Notes:`. Everything following that marker on subsequent lines (until the next slide separator) will be treated as notes for the current slide.

**Example:**

```markdown
# Slide with Notes

This content is visible on the slide.

Notes:
- Remember to mention the Q1 results.
- Don't forget to thank the team.
```

---

## Markdown Formatting within Slides

Standard Markdown formatting works within your slides:

*   **Headings:** Use `#`, `##`, `###`, etc., for slide titles and sections.
*   **Paragraphs:** Just write text as normal.
*   **Emphasis:** Use `*italic*` or `_italic_` and `**bold**` or `__bold__`.
*   **Lists:**
    *   Unordered: Use `-`, `*`, or `+`.
    *   Ordered: Use `1.`, `2.`, etc.
*   **Code:**
    *   Inline: \`code\`
    *   Blocks: Use fenced code blocks with optional language identifiers for syntax highlighting (theme depends on `highlight_theme` config).
        \`\`\`python
        def hello():
            print("Hello, MdSlides!")
        \`\`\`
*   **Links:** `[Link Text](https://example.com)`
*   **Images:** `![Alt Text](path/to/image.jpg)` or `![Alt Text](https://url/to/image.png)`

---

## Per-Slide Configuration (Frontmatter)

You can override global settings from `mkslides.yml` for a specific slideshow by adding YAML frontmatter at the very beginning of your Markdown file, enclosed in `---`.

A special `title` key in the frontmatter sets the display name for this slideshow on the main `index.html` page (if generated from a directory). You can also override `slides` options like the theme.

**Example:**

```markdown
---
title: My Special Presentation
slides:
    theme: solarized
    highlight_theme: github
---

# First Slide of Special Presentation

This presentation uses the Solarized theme.
```

*Note: The precedence is Frontmatter > `mkslides.yml` > Defaults.*

---

## Emoji Support :rocket:

MdSlides supports standard emoji shortcodes. Just include them in your Markdown! :tada: :smile:

**Example:**

```markdown
This presentation is going to be awesome! :rocket:
```

---

## Advanced: Preprocessing Scripts

For more complex modifications, MdSlides allows you to specify a `preprocess_script` in `mkslides.yml`. This points to a Python script containing a `preprocess` function that takes the raw Markdown string as input and returns a modified string. This can be used for tasks like custom text replacements, dynamic content injection, or other automated modifications before the Markdown is converted to HTML. Refer to the main configuration documentation for details.

---

## Summary

Using these basic Markdown features and MdSlides' separators, you can create well-structured and formatted presentations. For more advanced layouts, animations, themes, and plugin integrations, consult the Reveal.js documentation and the MdSlides configuration options related to `revealjs` and `plugins`.
