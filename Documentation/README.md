`CSAPIService` 是一个轻量的网络抽象层框架。

> 代码注释比较完备，部分细节可以直接查看代码。

## 框架组成

![APIServie](http://assets.processon.com/chart_image/6273fd0e7d9c08074fb5bad7.png)

框架按照网络请求流程中涉及的步骤将其内部分为几个角色：

- 请求者（APIRequest）：更准确的叫法应该是**构建请求者**，其主要作用就是将外部传入的相关参数经过相关处理构造成一个`URLRequest`实例，并且提供请求拦截器以及回调拦截器两种拦截器；
- 发送者（APIClient）：实际的网络请求发送者，目前默认是`Alamofire`，你也可以实现协议，灵活的对发送者进行替换；
- 解析者（APIParsable）：一般与`Model`是同一个角色，由`Model`实现协议从而实现从数据到实体这一过程的映射；
- 服务提供者（APIService）：整个框架的服务提供者，提供最外层的`API`，可以传入插件；

整个框架是按照`POP`的思想进行设计，将相关角色都尽量抽象成协议，方便扩展；

### APIRequest 协议

描述一个`URLRequest`实例需要的信息，并提供相应的拦截服务，在构造中我们可以设置返回的`ResponseModel`类型；

我们应当以`领域服务`为单位来提供对应的`APIRequest`，`领域服务`大部分会按照域名不同来区分，即 A 域名对应`AAPIRequest`，B 域名对应`BAPIRequest`。

> 内部实现默认有一个`DefaultAPIRequest`，主要目的是为大家提供一个示例，大家尽量不要直接使用它；

`APIRequest`的拦截器应用场景主要是整个`领域服务`级别的，一般添加的逻辑都是统一的逻辑。如：
- 发送前加上统一参数，Header 等信息；
- 数据回调到业务之前统一对一些 code 进行判断，如未登录自动弹出登录框等统一逻辑；

```swift
/// 请求发送之前
func intercept(urlRequest: URLRequest) throws -> URLRequest

/// 数据回调给业务之前
/// 利用 replaceResponseHandler 我们可以替换返回给业务的数据，还可以用作一些重试机制上等；
/// 需要注意的是一旦实现该方法，需要及时使用 replaceResponseHandler 将 response 返回给业务方。
func intercept<U: APIRequest>(request: U, response: APIResponse<Response>, replaceResponseHandler: @escaping APICompletionHandler<Response>)
```

### APIClient 协议

负责发送一个`Request`请求，我们可以调整`APIClient`的实现方式； 目前默认实现方式为`Alamofire`;

```swift
/// 网络请求任务协议
public protocol APIRequestTask {
    /// 取消
    func resume()

    /// 取消
    func cancel()
}

/// 网络请求客户端协议
public protocol APIClient {
    func createDataRequest(
        request: URLRequest,
        progressHandler: APIProgressHandler?,
        completionHandler: @escaping APIDataResponseCompletionHandler
    ) -> APIRequestTask

    func createDownloadRequest(
        request: URLRequest,
        to: @escaping APIDownloadDestination,
        progressHandler: APIProgressHandler?,
        completionHandler: @escaping APIDownloadResponseCompletionHandler
    ) -> APIRequestTask
}
```

`APIClient` 协议比较简单，就是根据请求类型区分不同的方法，其返回值也是一个协议（`APIRequestTask`），支持`resume`以及`cancel`操作。

> 目前操作只保留数据请求、下载请求两种方式，其他方式后续版本再补充；

### APIParsable 协议

```swift
public protocol APIParsable {
    static func parse(data: Data) throws -> Self
}
```

如上所示，`APIParsable`协议其实很简单，实现者通常是`Model`，就是将`Data`类型的数据映射成实体类型。

这是最底层的协议，在该协议下方目前还有`APIJSONParsable`协议，其继承了`APIParsable`协议，如下所示：

```swift
public protocol APIJSONParsable: APIParsable {}

extension APIJSONParsable where Self: Decodable {
    public static func parse(data: Data) throws -> Self {
        do {
            let model = try JSONDecoder().decode(self, from: data)
            return model
        } catch {
            throw APIResponseError.invalidParseResponse(error)
        }
    }
}
```

目前协议的默认实现方式是通过`Decodable`的方式将`JSON`转为`Model`。

当然

目前解析默认是由`JSON`通过`Decodable`的方式转为 Model，但如果后台返回的数据不是`JSON`，而是`XML`或者`Protobuf`等，那我们可以对`APIParsable`协议进行扩展。

目前协议默认实现了当`Model`实现了`Decodable` 协议时候的自动转换；

### APIService

## 默认使用方式

```swift
/// 返回的Model
struct HomeBanner: APIParsable, Codable {
    var interval: Int = 0
}

let request = DefaultNetRequest(responseType: HomeBanner.self, url: "你的API地止")

APIService.default.send(request: request) { result in
     switch result.result {
     case let .success(model):
          print(model)
     case let .failure(error):
          print(error)
     }
}
```

这是一个最简单的使用方式，我们可以直接在`.success`的回调中拿到我们反序列化后的`Model`。

但是这个方式肯定是满足不了我们业务中的场景的，那接下来我们看看怎么灵活扩展；

### 多主机

其实我们很有可能遇到 App 里面访问多个不同域名的服务器后台，那我们应该怎么处理呢？

我们可以自己实现`APIRequest`这个协议，如下：

```swift
public struct DomainOneNetRequest<T: APIParsable>: APIRequest {
    public var url: String

    public var method: NetRequestMethod

    public var parameters: [String: Any]?

    public var headers: NetRequestHeaders?

    public var httpBody: Data?

    public typealias Response = T

    /// 站点1 基础URL
    let domainOneBaseUrl = ""
}

extension DomainOneNetRequest {
    /// 最外层数据结构构建
    public init(responseType: Response.Type, url: String, method: NetRequestMethod = .get) {
        /// 拼接URL
        self.url = domainOneBaseUrl + url
        self.method = method
    }
}
```

这样每对应一个`domain`我们就定义这样一个`NetRequest`，我们在访问不同域名的 API 后台时，选择对应的`NetRequest`即可，并且我们可以把站点的域名收敛到构造函数里面，避免外面多次传入；

同时我们可以通过定义多个构造函数的方式给调用方提供是直接返回最外层数据结构的 Model 或者 真正数据对应的 Model。

```swift
extension DomainOneNetRequest {
    /// 数据层数据结构，最外层数据选用DefaultAPIResponseModel
    public init<S>(defaultDataType: S.Type, url: String, method: NetRequestMethod = .get) where DefaultAPIResponseModel<S> == T {
      	/// 拼接URL
        self.url = domainOneBaseUrl + url
        self.method = method
    }
}
```

## 更换最外层基础 Model

我们只需要按照`DefaultAPIResponseModel`的形式定义自己的 Model 就可以了，相应使用者换掉就 ok，上面场景就是一个例子；

```swift
public struct DomainOneAPIResponseModel<T>: APIParsable & Decodable where T: APIParsable & Decodable {
    public var code: Int
    public var msg: String
    public var data: T?
}
```
