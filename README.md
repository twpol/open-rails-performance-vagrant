# Open Rails Performance Vagrant

A simple [Vagrant](https://www.vagrantup.com/) virtual environment for logging and aggregating performance and other metrics from [Open Rails](http://openrails.org).

## Set up

You will need to install:
* [VirtualBox](https://www.virtualbox.org/)
* [Vagrant](https://www.vagrantup.com/)
* [Git](http://www.git-scm.com/) (_Optional_)

### If you have Git installed:
* Open Command Prompt or Windows PowerShell.
* Navigate to a place for storing the virtual machine configuration. You do not need to create a new subdirectory.
* Run the following commands:
```
git clone https://github.com/twpol/open-rails-performance-vagrant
cd open-rails-performance-vagrant
vagrant up
```
* Wait for the virtual machine to download, boot and be configured.

### If you do not have Git installed:
* [Download the ZIP](https://github.com/twpol/open-rails-performance-vagrant/archive/master.zip).
* Extract it to a place for storing the virtual machine configuration.
* Open Command Prompt or Windows PowerShell.
* Navigate to the place you extracted the files, specifically the `Vagrantfile`.
* Run the following command:
```
vagrant up
```
* Wait for the virtual machine to download, boot and be configured.

### Once the virtual machine is downloading...
After the download is complete, it should take just a few minutes for the booting and configuration to complete. You'll know it has finished successfully when you see a line like this:
```
==> default: Notice: Applied catalog in 168.41 seconds
```

## Controlling the virtual machine

* `vagrant up` starts or wakes up the virtual machine (including creation and configuration if needed).
* `vagrant suspend` puts the virtual machine to sleep.
* `vagrant reload` restarts the virtual machine.
* `vagrant destroy` deletes the virtual machine.
* When booting or restarting the virtual machine, it will display a line like this:
```
default: 80 (guest) => 2200 (host) (adapter 1)
```
This indicates which port the web server is running on; in this case it is 2200 (the default). Opening a browser on [http://127.0.0.1:2200/](http://127.0.0.1:2200/) will show you a page titled "Graphite" if it's all working.
* For the moment, there are two locations to see data from:
  * [http://127.0.0.1:2200/](http://127.0.0.1:2200/) - the Graphite Composer, which will show you as many data as you like all in a single graph.
  * [http://127.0.0.1:2200/dashboard/](http://127.0.0.1:2200/dashboard/) - the Graphite Dashboard, which will let you see many graphs at once, including showing multiple data in a single graph.

## Producing stats from code

The data collected goes to [statsd](https://github.com/etsy/statsd) through a UDP port (2201 is the default), where [its data type](https://github.com/etsy/statsd/blob/master/docs/metric_types.md) determines the processing done before being passed on to [Graphite](http://graphite.readthedocs.org/). You can add new entries simply by sending data with a new name - there's no need to configure anything ahead of time.

The following is an example of a simple C# class which counts _and_ times an operation in `Operation`. Note how both the counter and timer can have the same name. This is all you need to collect data - a `UdpClient` and a string converted to bytes.

```csharp
using System.Net.Sockets;
using System.Text.Encoding;

class StatsdExample {
    // Fields
    UdpClient Statsd = new UdpClient("127.0.0.1", 2201);
    byte[] StatsdCounter;

    public StatsdExample() {
        // Set up code - counters always send the same value so we pre-convert it.
        StatsdCounter = ASCII.GetBytes("statsd-example:1|c");
    }

    public Operation() {
        // Perform operation and set timeMS to duration in milliseconds.
        var timeMS = 1;

        // Collection code - just send precomputed value for counter.
        Statsd.Send(StatsdCounter, StatsdCounter.Length);

        // Collection code - convert and send value for timer.
        var bytes = ASCII.GetBytes("statsd-example:" + timeMS + "|ms");
        Statsd.Send(bytes, bytes.Length);
    }
}
```