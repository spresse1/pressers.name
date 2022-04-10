---
title: Getting new lenses for Lensfun
date: 2021-11-21 10:38:14
categories:
  - Germany
  - "Life in Germany"
slug: "getting-new-lenses-lensfun-notes"
images: [ "/static/images/stuttgart-rose.jpg", "/static/images/dark-woods.jpg" ]
---
![Rosen sind rot... And yes, by another name, they do still smell sweet! The focus of this image is two red roses seen from the side, positioned in the right-hand third of the picture and in focus. The rest of the image is out of focus. The power half of the image is rows of distant green grape vines. The next quarter of the image is out-of-focus homes, mostly white with red-orange roofs. And the last quarter right at the top of the image is a mostly cloudy sky.](/static/images/stuttgart-rose.jpg)

Since moving to Germany, I've started taking pictures. Lots here is beautiful, and my cell phone camera just didn't seem to be cutting it. So I bought a camera -- a (used) [Canon G5 X](https://www.usa.canon.com/internet/portal/us/home/explore/powershot-g-series/powershot-g5-x/explore-powershot-g-series-family-g5-x-rte/!ut/p/z1/lZJLb4JAEMc_iwePm5kF5HEEH6VGErFVZC-G4qKksktwI9pPXzTG2BppuqeZyW8e_5kFBktgIjnkm0TlUiS7xo-ZuQpC3_Zf-zh5saYjdMfvQ8fULK8fmhBdAHzyXAR2n2_bMw_dYIAjGhoazrRrfgvA2vsvgAEr03wNse5kDs-QEk1PM2JQe00SjTauQR3dMqmZ9pwznQpVqi3EaSKkWAle1_xjlUqhuFBd3MqCd5Efy52sGqOUNa_2W6nIhux5lfP9j1iPHG8weWRJlhT57nThSKX4b7mPelj7NqOzgPsKuPAMdE1n0Ne10Rm6Ai014mYG6-kMgQXRIec1zIWsiuYLvP1zwz7C-K-rRR7Ek-XX1K-BUSiL-byw9RP5zIKhbrDQ7XS-AaztfXg!/dz/d5/L2dBISEvZ0FBIS9nQSEh/?urile=wcm%3Apath%3A%2Fcanon_newweb_content%2Fhome%2Fexplore%2Fpowershot-g-series%2Fpowershot-g5-x%2Fexplore-powershot-g-series-family-g5-x-rte). The photos at the top and bottom of this post are a couple I'm proud of.

Of course, using a real camera means using real photo editing software. I run Linux on my laptop. Specifically, at the moment, Ubuntu. Ubuntu comes with [ShotWell](https://wiki.gnome.org/Apps/Shotwell). I chose to shoot raw photos, so that I would have the maximum flexibility in editing them. In turn, this means I need software that can edit raw photos. For that, I chose [DarkTable](https://www.darktable.org/) (which could probably do all the photo management, but I just haven't gotten around to trying that workflow).

I've only got one major pain point with DarkTable: Lens correction. When a camera takes a photo, the lens typically causes certain distortions. For digital cameras, these are easily corrected in software -- if you know what the distortions caused by the lens are. Most cameras can correct automatically. However, when shooting raw photos, my camera does not. And although DarkTable can do this automatically, it doesn't have the correct information for my camera in order to be able to do it!

If my camera were new, this wouldn't be particularly surprising. But it was released 4 years ago -- how is this information still missing? After digging in, it turns out Darktable relies on a library called [LensFun](http://lensfun.github.io/) for lens correction. Lens fun hasn't done a release in a while and (by policy), Ubuntu doesn't pull in updates to software until the software does a release. So no lens profile for me.

This means automatic correction doesn't properly get applied to my lens. Instead, I had to manually select the Canon G7X for every image -- and I'm lucky it uses the same lens, or I'd be out of luck for lens correction entirely!

So let's get this problem fixed.

# Finding the Lens Correction Information

A site related to LensFun [lists my camera as supported](https://wilson.bronger.org/lensfun_coverage.html) in "dev". So lets go find that support -- maybe we can insert it somewhere. After some hunting, I [found the data blob](https://github.com/lensfun/lensfun/blob/master/data/db/compact-canon.xml#L78) that contains the lens information for my camera.

# Finding the files on disk

We know we're looking for a file called "compact-canon.xml". So let's see if we can find it on disk:

```shell
$ find / -name compact-canon.xml 2>/dev/null
```

This looks through the entire disk for a file named "compact-canon.xml". The text of any errors goes to `/dev/null` (which automatically discards it).

It turns out Ubuntu has that file at `/usr/share/lensfun/version_1/compact-canon.xml`.

# Performing the update

So. Let's add the lens definition. I don't like making big changes, so I'm going to make the minimal change required for the lens correction to work. That means I'm just going to edit the file we found in the previous step and add the relevant lines.

I chose to add the lines after those for the Canon G7 X, which mirrors the setup in the official file.

These are the lines I added:

```xml
    <camera>
        <maker>Canon</maker>
        <model>Canon PowerShot G5 X</model>
        <model lang="en">PowerShot G5 X (3:2)</model>
        <mount>canonG7X</mount>
        <cropfactor>2.72</cropfactor>
    </camera>

    <camera>
        <maker>Canon</maker>
        <model>Canon PowerShot G5 X 4:3</model>
        <model lang="en">PowerShot G5 X (4:3)</model>
        <mount>canonG7X</mount>
        <cropfactor>2.94</cropfactor>
    </camera>

    <camera>
        <maker>Canon</maker>
        <model>Canon PowerShot G5 X 16:9</model>
        <model lang="en">PowerShot G5 X (16:9)</model>
        <mount>canonG7X</mount>
        <cropfactor>2.85</cropfactor>
    </camera>
```

# Finalizing

Then restart DarkTable and the lens correction should now be present.

This update will work at least until the next update -- but presumably the update will include the data we added, so that's not an issue.

![A path diverged in the wood and I... nope, not that. A maze of twisty passages, all.. nope. Eh. The forest is dark, green, and impenetrable. The forest floor is covered in brown leaves. We can see through a gap between the trees to a small clearing, where the ground is green and the sunlight lights the ground and the leaves which hang into the clearing.](/static/images/dark-woods.jpg)