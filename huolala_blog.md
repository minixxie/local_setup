# 《以docker、docker-compose架设本机调试开发环境》

github仓库：https://github.com/minixxie/local_setup

## TL;DR
```BASH
git clone https://github.com/minixxie/local_setup.git
cd local_setup/
make
docker ps -a
./test/create_order.sh
```

## 介绍
为了提高开发人员每天的工作效率，local setup(本地环境搭建)是个不可或缺的环节。有一个统一的本地环境搭建方法，可以：
1. 提高开发人员每天的工作效率
2. 让新员工尽快上手
3. 确保大家的环境一致
4. 减少和生产环境差异，减少差异导致的问题

### 提高开发人员每天的工作效率
一套统一标准的本地环境搭建，如何可以提高开发人员每天的工作效率呢？
这要讲到这个docker这个工具了。docker最近几年还是很火，成为了业界容器化的标准。对docker太多介绍这里就不说了，大家可以网上搜索更多的资料。
简单来说docker是一个进程隔离层，把每个进程隔离在一个独立的箱子里，可以有自己的IP地址、自己的process ID(pid)、自己的文件系统，让他的操作只限于一个范围内，对于系统会更安全。因为隔离在箱子里，而docker又提供了针对这些箱子的统一接口，（如docker start、docker kill等），所以针对各种服务的操作命令也可以统一起来。运维人员可以把这些箱子放一起排齐了，就像是一个个集装箱一样，所以docker的图标就用了一堆集装箱。

### 让新员工尽快上手
这套使用docker + docker-compose的本地环境，因为只需要新员工安装docker和docker-compose，不需要额外的任何软件，只要这两款软件版本符合就可以马上搭起来环境来玩了。可以说员工第一天就马上上手了。而且，docker + docker-compose这个标准可以执行在不同的OS上：Linux、MacOS、Windows都没问题。docker还提供了统一的标准接口来启动、停止、重启服务。所以不需要去特定学习各种不同语言的启动方式（如java用JRE、golang用go命令、nodejs还要`npm install`或yarn等）

### 确保大家的环境一致
因为docker是一套标准，大家都被逼用相同的方式来执行程序。再说docker容器里使用什么版本、插件，都在`Dockerfile`和`docker-compose.yml`定义好，放在代码仓库里，所以不同员工不会出现使用不同PHP版本的情况，不会出现环境变量不一致的情况，这些环境的差异往往是导致It works on my machine的问题。

### 减少和生产环境差异，减少差异导致的问题
讲到环境上的差异，docker确实还可以解决非生产环境和生产环境不一致的情况。因为docker可以执行在不同的OS上，所以可以轻易的把非常类似生产的环境也用同样的方式执行在本机上。这对服务器用Linux而本机用Windows的同学们帮助很大。因为这种差异可以说是极大的。要减少和生产环境的差异，前提也需要运维团队在生产环境也做容器化。简单的可以也用docker + docker-compose，先进一点可以用k8s（能提供应用横向扩展的功能），但同时要在本机环境上也搭建k8s（如使用minikube）。此文章只会探讨使用docker + docker-compose的情况。

为什么要减少和生产环境差异？很简单，这样你在本机做的功夫，测试过的东西，就不会白费了。要不然“能运作”只是在你本机的情况，并不代表上生产还能运作。


## 系统架构

<img src="https://mermaid.ink/svg/eyJjb2RlIjoiZ3JhcGggVERcbiAgICBhKFwiIFwiKSAtLT58aHR0cDo4MHxuZ2lueF9wcm94eVxuICAgIG5naW54X3Byb3h5XG4gICAgbmdpbnhfcHJveHkgLS0-fGh0dHB8IG9yZGVyc1xuICAgIG9yZGVycyAtLT58bXlzcWx8bXlzcWxbKG15c3FsKV1cbiIsIm1lcm1haWQiOnsidGhlbWUiOiJkZWZhdWx0In0sInVwZGF0ZUVkaXRvciI6ZmFsc2V9"/>

<span style="font-size:10px;">[chart](https://mermaid-js.github.io/mermaid-live-editor/#/edit/eyJjb2RlIjoiZ3JhcGggVERcbiAgICBhKFwiIFwiKSAtLT58aHR0cDo4MHxuZ2lueF9wcm94eVxuICAgIG5naW54X3Byb3h5XG4gICAgbmdpbnhfcHJveHkgLS0-fGh0dHB8IG9yZGVyc1xuICAgIG9yZGVycyAtLT58bXlzcWx8bXlzcWxbKG15c3FsKV1cbiIsIm1lcm1haWQiOnsidGhlbWUiOiJkZWZhdWx0In0sInVwZGF0ZUVkaXRvciI6ZmFsc2V9)</span>

1. `nginx_proxy`是唯一一个监听80端口的容器，把所有进入到系统的请求通过80端口接入。
2. `orders`是其中一个微服务，所有微服务都由`nginx_proxy`做反向代理(reverse proxy)，转发http请求。
3. `mysql`是目前系统中唯一的数据库，以后需要更多不同的数据库，可以再添加其他的容器（如redis、mongodb、postgres等）。

## 实践

```BASH
make
```
```BASH
MYSQL_ROOT_PASSWORD=hello123 docker-compose -f docker-compose-local.yml up --build -d
Building orders_db
Step 1/3 : FROM mysql:8.0.12
...
```
`Makefile`里预先已经写好命令，使用docker-compose命令并且出发docker构建(`--build`)，就会构建docker镜像并且用容器的方式来执行系统的各个部分。这些有：
1. `nginx_proxy` - nginx反响代理服务
2. `local_orders` - orders微服务，`local_`前缀代表这个是本机环境的
3. `mysql` - mysql数据库
4. `local_orders_db` - orders的数据库

```BASH
docker ps -a
```
```BASH
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS                 PORTS                 NAMES
b16f8934bdf4        local_orders:dont_push       "/main"                  7 hours ago         Up 7 hours (healthy)   80/tcp                local_orders
67c22551ab66        mysql_migrate:dont_push      "docker-entrypoint.s…"   7 hours ago         Up 7 hours (healthy)   3306/tcp, 33060/tcp   local_orders_db
7236ecfb282b        mysql:8.0.12                 "docker-entrypoint.s…"   7 hours ago         Up 7 hours (healthy)   3306/tcp, 33060/tcp   mysql
2f2b0b553775        jwilder/nginx-proxy:alpine   "/app/docker-entrypo…"   7 hours ago         Up 7 hours (healthy)   0.0.0.0:80->80/tcp    nginx_proxy
```

### local_orders_db
值得一提的是这个`local_orders_db`容器。有`mysql`数据库，为啥还要一个`local_orders_db`数据库呢？其实这个容器不是数据库。让我们看一下它的docker-compose文件`orders/orders_db/docker-compose-local.yml`：
```YAML
services:
    orders_db:
      image: mysql_migrate:dont_push
...
      command:
        - /bin/sh
        - -c
        - |
            /wait-for.sh mysql:3306
            mysql -A -hmysql -uroot -p${MYSQL_ROOT_PASSWORD} < /db/local_db.sql
            mysql -A -hmysql -uroot -p${MYSQL_ROOT_PASSWORD} < /db/local_user.sql
            /migrate -source file:///db/migrations -database "mysql://root:${MYSQL_ROOT_PASSWORD}@tcp(mysql:3306)/local_orders" up
            sleep 365d # sleep for 1 yr
      healthcheck:
        test: /verify-schema-version.sh mysql root hello123 local_orders
...
```
首先`mysql_migrate`是一个`mysql`镜像+`golang/migrate`工具的镜像。`golang/migrate`工具是一个很好用的数据库版本控制工具，详情请看：https://github.com/golang-migrate/migrate

简单来说，使用`golang/migrate`的前提是我们要把数据库结构的每次改动，录入为SQL文件，提交到git仓库里：
```
$ ls orders/orders_db/
docker-compose-local.yml  local_db.sql              local_user.sql            migrations/
$ ls -l orders/orders_db/migrations/
total 32
-rw-r--r--  1 simon.tse  staff   21 May  5 01:16 00001_orders.down.sql
-rw-r--r--  1 simon.tse  staff  663 May 12 01:11 00001_orders.up.sql
-rw-r--r--  1 simon.tse  staff   42 May  5 01:48 00002_orders_index.down.sql
-rw-r--r--  1 simon.tse  staff   62 May  5 01:47 00002_orders_index.up.sql
```
注意到每个号码（00001、00002）都有“一对”文件，他们是天生一对，一up一down。因为`golang/migrate`工具要求我们把所有的数据库结构变动，都提供回滚方案。比如：
```SQL
$ cat orders/orders_db/migrations/00002_orders_index.up.sql 
CREATE INDEX idx_order_datetime ON `orders`(`order_datetime`);
```
的回滚语句：
```SQL
$ cat orders/orders_db/migrations/00002_orders_index.down.sql 
DROP INDEX idx_order_datetime ON `orders`;
```

那么这个`local_orders_db`容器是干什么的呢？
它一起来，就会用`golang/migrate`工具，把你需要的数据库改动，从头到尾做一次，就会把数据库最新的结构做出来了。这就是这句起的作用（主要就是创建表结构之类的）：
```BASH
/migrate -source file:///db/migrations -database "mysql://root:${MYSQL_ROOT_PASSWORD}@tcp(mysql:3306)/local_orders" up
```
而且，这个容器创建完数据库结构后，会休眠一年：
```BASH
sleep 365d # sleep for 1 yr
```
这个主要原因是保持容器在那，让health-check得以不断的执行：
```
      healthcheck:
        test: /verify-schema-version.sh mysql root hello123 local_orders
        interval: 60s
```
这几行的意思是，每60秒执行 `/verify-schema-version.sh` 这个脚本，检查一下`local_orders`这个数据库结构，是否健康。健康的定义是，数据库里的版本是否和`/migrations`目录里的一致。目前`/migrations`目录里最大的号码为`00002`，所以在数据库里有记录version=2，就是健康。健康状态会反应在docker容器上，留意"(healthy)"文字：
```BASH
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS                 PORTS                 NAMES
67c22551ab66        mysql_migrate:dont_push      "docker-entrypoint.s…"   7 hours ago         Up 7 hours (healthy)   3306/tcp, 33060/tcp   local_orders_db
```

这个健康状态非常重要，因为它可以使用在容器的启动顺序上，请见项目目录里的docker-compose文件 `docker-compose-local.yml`：
```YAML
  orders_db:
    extends:
      file: ./orders/orders_db/docker-compose-local.yml
      service: orders_db
    depends_on:
      mysql:
        condition: service_healthy
  orders:
    extends:
      file: ./orders/docker-compose-local.yml
      service: orders
    depends_on:
      orders_db:
        condition: service_healthy
```
`orders`服务启动的前置条件是`orders_db`容器健康，而`orders_db`启动的前置条件是`mysql`容器健康。这个是用`depends_on`这个键来达成的。
启动的顺序对于本机环境来说很重要。如果启动早了，应用程序没有处理好的话，就会报错说连不上mysql，服务就会死掉。

## 测试
在本机可以测试API，是能玩起来的必须一步。同学们会有很多不同的工具可以选择，比如PostMan、VS Code自带的http文件、cURL等，甚至可以用mocha做API测试。此处为了简单只用cURL：
```BASH
Simons-MacBook-Pro:local_setup simon.tse$ ./test/create_order.sh 
Note: Unnecessary use of -X or --request, POST is already inferred.
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to 127.0.0.1 (127.0.0.1) port 80 (#0)
> POST /rpc/createOrder HTTP/1.1
> Host: orders.local
> User-Agent: curl/7.54.0
> Accept: */*
> Content-Length: 3
> Content-Type: application/x-www-form-urlencoded
> 
* upload completely sent off: 3 out of 3 bytes
< HTTP/1.1 200 OK
< Server: nginx/1.17.6
< Date: Wed, 03 Jun 2020 08:46:47 GMT
< Content-Type: application/json; charset=utf-8
< Content-Length: 20
< Connection: keep-alive
< 
* Connection #0 to host 127.0.0.1 left intact
{"order":{"from":{"lat":22.338322,"lng":114.147328},"id":26,"to":{"lat":22.278156,"lng":114.172762},"totalPrice":"80"}}
```
上面这个测试脚本`create_order.sh`是测试创建一个订单的接口。如果成功，会返回HTTP 200和正确的JSON response。

## 程序员每天的生活

有了这个本机环境搭建的方法，程序员每天的效率就大大的提高了。

这个本机环境可以随时重新搭起来，因为有了规范的做法，每天早上回到公司，只要一个`make`，系统就起来了，就可以开始改代码了。

要注意的是，改动代码时希望容器里会热加载新的代码，这和用什么语言有关系。比如用PHP，只需要在容器做个目录挂载到容器里，改动的代码可以在下一个请求时就被PHP-fpm加载到。比如用golang，用者需要更改Dockerfile，使用realize，要不然每次需要杀掉容器再重新启动：
```BASH
docker rm -f local_orders
make
```

最后，希望这个local_setup的例子能帮到大家！