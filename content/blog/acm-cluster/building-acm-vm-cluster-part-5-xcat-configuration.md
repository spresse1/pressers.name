---
title: "Building the ACM VM Cluster, Part 5: xCat configuration"
date: 2012-09-09 19:41:05
slug: "building-acm-vm-cluster-part-5-xcat-configuration"
categories:
  - "ACM"
  - "ACM Cluster"
---

In [part 4 of this series](/2012/09/09/building-acm-vm-cluster-part-4-xcat-install/), we installed xCat.  Now its time to configure it.

# But First...

But first, lets talk a little about how you interact with xCat.  xCat stores its configuration files in "tab"s - tables.  In the default case, these are sqlite tables, though some will try to convince you to change it to MySQL.  Unless you're running thousands of nodes or continually hitting xCat, I see no point in this changeover and therefore will not cover it.

Interaction with xCat happens primarily through three commands: `chnode`, `chtab` and `tabedit`.  However, `nodels` and `tabdump` are also useful for seeing what xCat got out of your input.  For detail on these commands, read the man pages for each.  However, here is a quick summary:

*   `chnode`: change configuration details on a node
*   `chtab`: Change configuration by key in a table
*   `tabedi`t: Manually edit a table
*   `nodels`: show all details associated with a particular node
*   `tabdump`: show the data stored in a tab

If you're looking for information on a table try:

```shell
$ man 5 [tablename]
```

assuming you installed the man command.  (See, there was a reason I mentioned it!)

# Change some Config!

## Site Setup

xCat stores most of its global setting in the "site" table.  So lets edit that one:

```shell
# tabedit site
```

Okay, now we have to make things work just as we expect.  So we have to change some critical default values:

```shell
"forwarders","[your external dns servers]"
"master","[Master node name]",,
"nameservers","172.16.0.1",,
"ntpservers","172.16.0.1",,
```

Save and exit.  xCat will let you know if you've made a syntactical mistake, to don't worry too much about those.  If you'd like the domain name of your cluster set, you should also consider setting the "domain" attribute in the same way as the above.

## Adding Nodes

Now its time to add some nodes.  To do this, we'll use a new command, nodeadd and take advantage of its powerful regular expressions to add many nodes at once.

```shell
# nodeadd node[001-016] groups=compute,apc,vm,core
```

Note that this adds node001 through node016 to the xCat database and puts them in the groups compute, apc, vm, and core, which represent generic nodes, those controlled by our APC switched PDUs, those running VMs, and 'core' VM nodes - those which will run the ACM's core services.

Lets also add the management nodes while we're at it:

```shell
# nodeadd master groups=management,masters
# nodeadd master1 groups=management,masters
# nodeadd master2 groups=management,masters
```

In this case, I have added an entry for the shared IP address under the name master, then given each of the physical nodes that can run the master configuration the name master1 or master2.

And next, some switches:

```shell
# nodeadd eth-switch[1-4] groups=management,switches,eth-switches
# nodeadd myricom-switch groups=management,switches,fiber-switches
```

## Give Nodes Addresses

The next thing we have to do is set up the static IP addressing for within the cluster.  We're going to be doing this through xCat, because it makes life simpler if configuration needs to only be changed in one place.  Lets start with the management nodes:

```shell
# nodech master hosts.ip=172.16.0.1
# nodech master1 hosts.ip=172.16.0.2
# nodech master2 hosts.ip=172.16.0.3
# nodech myricom-switch hosts.ip=172.16.0.11
```

Now, lets give the switches and compute nodes IP addresses:

```shell
# nodech eth-switches hosts.ip='|\D+(\d+)$|172.16.0.($1+4)|'
# nodech compute hosts.ip='|\D+(\d+)$|172.18.0.($1+0)|'
```

These lines add the compute nodes, as a batch, so that they follow a regular expression.  This saves us having to put them all in individually.  Please do note that if you have more than 254 nodes (and therefore need to use more than just the 172.18.0.0/16 space) your regex will get more complicated.

Now, we have one last bit of other configuration to do - Assigning IP addresses for the fiber cards of the nodes.  To do this, we're going to use the 'otherinterfaces' column of the hosts table.

```shell
# nodech compute hosts.otherinterfaces='|\D+(\d+)$|node($1)-fiber:172.20.0.($1+0)|'
```

## Generate /etc/hosts

xCat can automatically generate /etc/hosts, which is then used by other servers on the system to know where to find and what to name nodes.  So.  Lets let xCat do the work for us and generate this:

```shell
# makehosts
```

Generally, whenever you make a change to the hosts table, you should rerun makehosts to regenerate `/etc/hosts`.

# Conclusion

So.  Now xCat knows about the network topology.  In the next section, we're actually going to set the network up!