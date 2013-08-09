# 滨港工业城官方网站前端

## Demo

http://zenozeng.github.io/bingang-industrial-park/

## Features

### Single Page

页面局部刷新，无缝切换，同时利用 window.location.hash 保证路由与 view 的对应关系

### 本地两层缓存

使用 localStorage 缓存技术，先反馈页面，再把更新请求加入后台队列。

```coffee
if RAMCache
    RAMCache
else
    if localStorageCache
        Return localStorageCache
        unless Cache Timestamp > Backend Data Modified Timestamp
            updateData
    else
        getData
        writeToRAMCache
        writeToLocalStorageCache
```

### 图片预加载

利用动画间隙预加载图片，减少页面卡顿感

### Wordpress作为后端

透过 Wordpress JSON API 获取数据，既有 Wordpress 优雅友好的后端，又有纯静态页面的快速响应

### 社会化评论

使用 Uyan 社会化评论，一键实现微博、人人等社交登陆，方便留言，简化意见收集成本

## For Developers

### 应用架构

router -\> view -\> data -\> wp

- config.coffee

    配置文件，后端的地址，评论的地址，本应用的地址，首页显示的模块等具体设置

- require/wp.coffee

    Wordpress 接口抽象层

- data.coffee

    数据接口抽象层，负责缓存、更新，数据层事件触发

- gallery.coffee

    首页图片的展示，负责预加载、动画

- view.coffee

    负责HTML填充，view层事件触发

- routes.coffee

    路由层

### 修改？

- coffee文件 对应在 src/

- less 文件位于 css/styles.less

```bash
cake build
```

## 参考

- HTML 5.1 Nightly

    http://www.w3.org/html/wg/drafts/html/master/sections.html (Editor's Draft 1 August 2013)

- CoffeeScript Doc

    https://github.com/netzpirat/codo

## Requirements

### Wordpress

### WP-JSON-API

### WP-JSON-API-Extra

