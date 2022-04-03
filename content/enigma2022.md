---
title: Enigma 2022 Resources and Q&A
date: 2022-02-01 00:00:00
categories:
  - Cybersecurity
  - Presentations
slug: "enigma2022"
---

This page contains resources related to my February 2nd, 2022 talk, "[Broken Captchas and Fractured Equity: Privacy and Security in hCaptcha's Accessibility Workflow](https://www.usenix.org/conference/enigma2022/presentation/presser)". Each section of this page begins with a level 2 header.

## Table of Contents

*   [Slides](#slides)
*   [External Resources on Accessibility Technology and Software Accessibility](#external_resources)
*   [Code](#code)
*   [Video](#video)
*   [Frequently Asked Questions](#faq)
*   [Questions, Comments and Other Things](#questionscomments)

## Slides

Download the slides as [Open Office ODP](https://pressers.name/static/slidesets/SPresserEnigma2022.odp) or [PowerPoint PPTX](https://pressers.name/static/slidesets/SPresserEnigma2022.pptx). These include speaker's notes with approximately what I'll say, transcripts and descriptions of the videos, and descriptions of all images used in the talk.

## External Resources on Accessibility Technology and Software Accessibility {id="external_resources"}

Want to learn more about accessibility technology? These pages are organized approximately from least to most technical. I've tried to focus on resources by people with disabilities, or at least recommended by them.

There are many excellent resources out there. If I've missed a good one, please let me know, either [by email](mailto:enigma2022@pressers.name) or [via the contact form](/contact).

*   [WebAIM](https://webaim.org/) covers web accessibility from the basics ([introduction to web accessibility](https://webaim.org/intro/), [disability types and design considerations](https://webaim.org/articles/#usersperspective), [evaluation guides](https://webaim.org/articles/evaluationguide/)) through intermediate topics ([ARIA roles](https://webaim.org/techniques/aria/), [JavaScript](https://webaim.org/techniques/javascript/) and [CSS](https://webaim.org/techniques/css/), [content specifically for users of assistive technology](https://webaim.org/techniques/css/invisiblecontent)) and many references to where more information may be found.
*   And, of course, the W3C, which writes the [Web Content Accessibility Guidelines (WCAG)](https://www.w3.org/WAI/standards-guidelines/wcag/), the standard for web accessibility and [ARIA](https://www.w3.org/WAI/standards-guidelines/aria/), which allows annotation of elements by role on the page, if needed. These are written and maintained by the [Web Accessibility Initiative (WAI)](https://www.w3.org/WAI/), which also hosts an excellent [introduction to accessibility](https://www.w3.org/WAI/fundamentals/accessibility-intro/).

## Code

All [the code for the vulnerability](https://github.com/spresse1/handicaptcha) can be found on my GitHub account.

## Video

*   [Screenreader demo (without visuals)](https://youtu.be/RFj9N_Vnn64) - a short task performed by a screenreader user, with no visuals.
*   [Screenreader demo (with visuals)](https://youtu.be/FMpJhxVawgA) - the same short task performed by a screenreader user, with visuals.
*   [Enigma Slides hCaptcha Bypass Demo](https://youtu.be/pgEr_mU7kC0) - the shortened version of the hCaptcha bypass demo embedded in my Enigma slides.
*   [hCaptcha Full Bypass Demo Video](https://youtu.be/kmh9FFuXNVg) - this is the demo video that was sent with the responsible disclosure report. I consider it very boring and cant imagine why you'd want to watch it, but it's here anyway.

## Frequently Asked Questions {id="faq"}

### What is Assistive Technology?

Anything that helps someone do something they couldn't otherwise do or improve their experience/ability to do something. In this context, that's mostly alternative input and output devices or software for computers. For example, foot keyboards and [mice](https://www.3drudder.com/foot-mouse/), [puff-and-sip devices](https://en.wikipedia.org/wiki/Sip-and-puff), [screenreaders](https://www.nvaccess.org/), [screen magnifiers](https://en.wikipedia.org/wiki/Screen_magnifier), and even [ergonomic keyboards](https://en.wikipedia.org/wiki/Ergonomic_keyboard) (especially when used for symptoms or prevention of carpal tunnel). In a non-computer context, items like eyeglasses and contacts are also assistive technologies.

### What is a CAPTCHA?

A captcha is a "Completely Automated Public Turing test to tell Computers and Humans Apart". In other words, it's a short task that is trivial for humans to do and difficult to impossible for computers to do. Captchas are used for many reasons on the internet, almost all of which have to do with excluding automation from websites.

### What is hCaptcha?

[hCaptcha](https://www.hcaptcha.com/) is a commercial captcha product, built by [Intuition Machines](https://www.imachines.com/). Intuition Machines uses hCaptcha to provide data labeling, specifically for visuals. So if a researcher has a large set of photos and wants them labeled by objects they contain, they can pay Intuition Machines to have labels applied. Intutition Machines uses hCaptcha to crowdsource this labeling. They show the images and have users identify what is in them. Usually users are asked to select all images containing a certain item.

hCaptcha is somewhat unique in that they pay (some) website owners to use hCaptcha. And somehow there's a blockchain involved in all of this -- but it isn't really relevant to this work.

Ideally, hCaptcha is a mutually beneficial arrangement. Researchers get labeled data and website owners are able to prevent automation on their websites, improving the experience for their users (and possibly getting paid in the process!).

### Did you disclose this vulnerability before speaking about it?

Of course! I did this work under the terms of [hCaptcha's bug bounty program](https://github.com/hCaptcha/bounties) and [Cloudflare's HackerOne program](https://hackerone.com/cloudflare).

On June 3, 2021, I sent hCaptcha support and security an email describing the issue. The first (non-automated) response came the next day. We discussed the issue more from there, but I was not informed of any action by hCaptcha.

Additionally, I disclosed this to Cloudflare on June 14th, and received a response on June 22nd, which closed the issue.

### This requires making accounts at scale to work. Were you able to do so?

No, though I did ask permission to do so. As soon as I was able to use automation to register one account, I reached out to hCaptcha to report my findings. In that communication, I was very clear that I had not attempted to do any work at scale. I also requested permission to try it at scale, which I did not receive.

### What do you want me to take away from this?

I'm hoping you take away that accessibility is a core component of modern software engineering and must be involved in every design from the beginning.

### So is hCaptcha just bad and inaccessible?

This answer has to be given in two parts. First, let's talk about hCaptcha an accessibility on a relative scale, compared to the rest of the CAPTCHA industry. On this scale, they're doing great! They thought about people with disabilities and put in place a solution for them before their product launched. Yes, it didn't work perfectly, but it did work. Which is better than [some](https://phabricator.wikimedia.org/T6845) [other](http://www.geetest.com/en/) [captchas](https://www.capy.me/products/puzzle_captcha/) that don't have any accessible options (and yes, I am calling out wikimedia for having an 16 year old bug that their captcha is inaccessible and not having fixed it yet. That bug is old enough to drive!). And while they do get beaten by [other options](http://simplyaccessible.com/article/googles-no-captcha/), their automated workflow was, in my opinion, well above industry average.

However, on an absolute scale, the accessibility still sucks. It imposes a significant privacy and time penalty on those who use the accessible workflow. Privacy in that the user's activity across the web can now be tied to their email address. While hCaptcha's terms are clear that they do not do this, there is no real way to verify that -- and it's scary enough they have the technical capability. And time in that using the accessibility workflow is simply slower and more complicated. Especially once you consider all the ways where things just don't work right. For example, the automation I wrote has to tab past the hCaptcha widget and then back to it, because it isn't possible to get to the checkbox otherwise. Or that (last I checked) the announcement that the accessibility cookie was set did not read correctly to screen readers. This makes it evident that despite their good intentions, they probably have not run user tests with users with disabilities.

In sum, I believe hCaptcha is good people doing their best to come up with a solution to a very complicated problem. I really appreciate that they're at least thinking about people with disability and assistive technology and how both interact with their product. That said, the solution they're coming up with are unfortunately halfhearted. As a solution, it doesn't work for people with disabilities in ways that are very obvious to anyone with a disability or even the modicum of experience with accessibility technology I picked up working on this product. These indicate that hCaptcha likely is not testing the accessible workflow for accessibility -- or if they are doing so, they are not using experienced accessibility testers.

### How did you get into doing accessibility work?

I don't do accessibility work.  In my day job I work on supercomputers. However, that work does mean I spend a lot of time thinking about how systems work and how various parts of a solution work together (or don't). That's what lead to me spotting that hCaptcha can be automated. This is not a coding flaw, but a design flaw. They simply failed to verify that the accessible workflow met the design goals.

I do have some prior experience seeing how accessibility can make a difference. When I was in high school and college, I taught sailing, in part in a universal access program. Before being part of that program, I had never thought about alternative ways to sail. It was a boat, it had controls, and you used them. But participating in the program as an instructor made it very obvious to me very quickly that I was wrong. I saw firsthand how adaptations could be made so that everyone could sail. Just because there is an obvious way to do something based on my experience and perspective does not mean it is the only way to do something. It's a lesson that has helped me design better software systems and think more flexibly about anything I interact with.

## Questions, Comments, Other Things? {id="questionscomments"}

Do you have questions, comments, or other things you would like to discuss with me? If so, please email {{< cloakemail address="enigma2022@pressers.name" >}}.