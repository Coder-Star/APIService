# CSAPIService

[![Version](https://img.shields.io/cocoapods/v/CSAPIService.svg?style=flat)](https://cocoapods.org/pods/CSAPIService)
[![License](https://img.shields.io/cocoapods/l/CSAPIService.svg?style=flat)](https://cocoapods.org/pods/CSAPIService)
[![Platform](https://img.shields.io/cocoapods/p/CSAPIService.svg?style=flat)](https://cocoapods.org/pods/CSAPIService)
[![Doc](https://img.shields.io/badge/doc-https%3A%2F%2Fcoder--star.github.io%2FAPIService%2F-lightgrey)](https://coder-star.github.io/APIService/)

`CSAPIService` 是一个轻量的 Swift 网络抽象层框架，将请求、解析等流程工作分成几大角色去承担，完全面向协议实现，利于扩展。

## 使用方式

```ruby
pod 'CSAPIService'
```

其实原来的名称为`APIService`，但是因为该名在`CocoaPods`已经被占用了，就加了前缀，但是在使用时，模块名称依然是`APIService`。

> 代码注释比较完备，部分细节可以直接查看代码。

## 特性

- 支持Request级别拦截器，并支持对响应进行异步替换；
- 支持插件化拦截器；
- 面向协议，角色清晰，方便功能扩展；

## 框架组成

![APIService](http://assets.processon.com/chart_image/6273fd0e7d9c08074fb5bad7.png)
> 箭头指的是发送流程，实心点指的是数据回调流程；
> 高清图可见 [链接](https://www.processon.com/view/link/6274d2db1efad40df0236a83)

框架按照网络请求流程中涉及的步骤将其内部分为几个角色：

- 请求者（APIRequest）：更准确的叫法应该是**构建请求者**，其主要作用就是将外部传入的相关参数经过相关处理构造成一个`URLRequest`实例，并且提供请求拦截器以及回调拦截器两种拦截器；
- 发送者（APIClient）：实际的网络请求发送者，目前默认是`Alamofire`，你也可以实现协议，灵活的对发送者进行替换；
- 解析者（APIParsable）：一般与`Model`是同一个角色，由`Model`实现协议从而实现从数据到实体这一过程的映射；
- 服务提供者（APIService）：整个框架的服务提供者，提供最外层的`API`，可以传入插件；

整个框架是按照`POP`的思想进行设计，将相关角色都尽量抽象成协议，方便扩展；

### APIRequest 协议

描述一个`URLRequest`实例需要的信息，并提供相应的拦截服务，在构造中我们可以设置返回的`ResponseModel`类型；

我们应当以`领域服务`为单位来提供对应的`APIRequest`，`领域服务`大部分会按照域名不同来划分，即 A 域名对应`AAPIRequest`，B 域名对应`BAPIRequest`。

`APIRequest`的拦截器应用场景主要是整个`领域服务`级别的，一般添加的逻辑都是统一的逻辑。如：
- 发送前加上统一参数，Header 等信息；
- 数据回调到业务之前统一对一些 `code` 进行判断，如未登录自动弹出登录框等统一逻辑；

```swift
/// 请求发送之前
func intercept(urlRequest: URLRequest) throws -> URLRequest

/// 数据回调给业务之前
/// 利用 replaceResponseHandler 我们可以替换返回给业务的数据，还可以用作一些重试机制上等；
/// 需要注意的是一旦实现该方法，需要及时使用 replaceResponseHandler 将 response 返回给业务方。
func intercept<U: APIRequest>(request: U, response: APIResponse<Response>, replaceResponseHandler: @escaping APICompletionHandler<Response>)
```

### APIClient 协议

负责发送一个`Request`请求，我们可以调整`APIClient`的实现方式； 目前默认实现方式为`Alamofire`，其中使用别名等方式做了隔离。

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

这是最上层的协议，在该协议下方目前还有`APIJSONParsable`协议，其继承了`APIParsable`协议，如下所示：

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

当然我们可以根据项目数据交换协议扩展对应的解析方式，如 XML、`Protobuf`等；

```swift
public typealias APIDefaultJSONParsable = APIJSONParsable & Decodable
```

同时为方便业务使用，添加了一个别名，如果使用默认方式 `Decodable` 进行解析，最外层 `Model` 就可以直接实现该协议。

### APIPlugin

```swift
public protocol APIPlugin {
    /// 构造URLRequest
    func prepare<T: APIRequest>(_ request: URLRequest, targetRequest: T) -> URLRequest

    /// 发送之前
    func willSend<T: APIRequest>(_ request: URLRequest, targetRequest: T)

    /// 接收结果，时机在返回给调用方之前
    func willReceive<T: APIRequest>(_ result: APIResponse<T.Response>, targetRequest: T)

    /// 接收结果，时机在返回给调用方之后
    func didReceive<T: APIRequest>(_ result: APIResponse<T.Response>, targetRequest: T)
}
```

在具体网络请求层次上提供的拦截器协议，这样业务使用过程中可以感知到请求请求中的重要节点，从而完成一些逻辑，如`Loading`的加载与消失就可以通过构造一些对应的实例去完成。

### APIService

这是最外层的供业务发起网络请求的`API`。

```swift
open class APIService {
    private let reachabilityManager = APINetworkReachabilityManager()

    public let client: APIClient

    public init(client: APIClient) {
        self.client = client
    }

    /// 单例
    public static let `default` = APIService(client: AlamofireAPIClient())
}
```

`APIService`提供**类方法**以及**实例方法**，其中类方法就是使用的`default`实例，当然也可以其他的`APIClient`实现实例然后调用实例方法，等后续对底层实现进行替换是，只需要替换`default`实例的默认实现就可以了。

```swift
public func sendRequest<T: APIRequest>(
        _ request: T,
        plugins: [APIPlugin] = [],
        encoding: APIParameterEncoding? = nil,
        progressHandler: APIProgressHandler? = nil,
        completionHandler: @escaping APICompletionHandler<T.Response>
    ) -> APIRequestTask? { }
```

实例方法定义如上，支持传入`APIPlugin` 实例数组。

## 业务使用实践

> 相关代码在 Demo 工程里面可以看到。

### 最外层的 Model

```swift
/// 网络请求结果最外层Model
public protocol APIModelWrapper {
    associatedtype DataType: Decodable

    var code: Int { get }

    var msg: String { get }

    var data: DataType? { get }
}
```

对于大多数的网络请求而言，拿到的回调结果最外层肯定是最基础的 Model，也就是所谓的`BaseReponseBean`，其字段主要也是`code`、`msg`、`data`。

我们定义这样的一个协议方便后续使用，其实这个协议当时是直接放在库里面的，后来发现库内部对其没有依赖，其更多是一种更优的编程实践，就提出来放到了 Demo 工程里面去。

我们需要构造一个实体去实现该协议，

```swift
public struct CSBaseResponseModel<T>: APIModelWrapper, APIDefaultJSONParsable where T: Decodable {
    public var code: Int
    public var msg: String
    public var data: T?

    enum CodingKeys: String, CodingKey {
        case code
        case msg = "desc"
        case data
    }
}
```

因为最外层的 `CSBaseResponseModel` 已经满足了 `APIDefaultJSONParsable`协议，所以业务Model不需要再实现该协议了，而是直接实现`Decodable`就好。

> 有的小伙伴可能会想不能直接使用实体吗？为什么还需要一个协议，这个协议在后面会用到。

### 业务 APIRequest

```swift
/// 注意这个 CSBaseResponseModel
protocol CSAPIRequest: APIRequest where Response == CSBaseResponseModel<DataResponse> {
    associatedtype DataResponse: Decodable

    var isMock: Bool { get }
}

extension CSAPIRequest {
  	var isMock: Bool {
        return false
    }

    var baseURL: URL {
        if isMock {
            return NetworkConstants.baseMockURL
        }
        switch NetworkConstants.env {
        case .prod:
            return NetworkConstants.baseProdURL
        case .dev:
            return NetworkConstants.baseDevURL
        }
    }

    var method: APIRequestMethod { .get }


    var parameters: [String: Any]? {
        return nil
    }

    var headers: APIRequestHeaders? {
        return nil
    }

    var taskType: APIRequestTaskType {
        return .request
    }

    var encoding: APIParameterEncoding {
        return APIURLEncoding.default
    }
  
    public func intercept(urlRequest: URLRequest) throws -> URLRequest {
        /// 我们可以在这个位置添加统一的参数、header的信息；
        return urlRequest
    }

    public func intercept<U: APIRequest>(request: U, response: APIResponse<Response>, replaceResponseHandler: @escaping APICompletionHandler<Response>) {
        /// 我们在这里位置可以处理统一的回调判断相关逻辑
        replaceResponseHandler(response)
    }
}
```

### APIResult 扩展

我们通过`APIResult`最终获得的是最外层的`Model`，那对于大部分业务方而言，他们拿到数据后还会有一些通用逻辑，如：

- 根据`code`值判断请求是否成功；
- 错误本地化；
- 获取实际的`data`数据；
- ...

而这些逻辑在每一个`域名服务`又可能是不同的，属于业务逻辑，所以不宜放入库内部。

那对于这些逻辑，我们就可以对 `APIResult` 进行扩展，将这些逻辑收进去，业务方可以根据自己的需求决定在拿到`APIResult`之后是否还调用这个扩展。

如果有多种逻辑，可以考虑增加一些特定前缀去区别，如下面的`validateResult`我们可以扩展为多个 -- `csValidateResult`，`cfValidateResult`等等。

```swift
public enum APIValidateResult<T> {
    case success(T, String)
    case failure(String, APIError)
}

public enum CSDataError: Error {
    case invalidParseResponse
}

/// APIModelWrapper 在这个地方用到了
extension APIResult where T: APIModelWrapper {
    var validateResult: APIValidateResult<T.DataType> {
        var message = "出现错误，请稍后重试"
        switch self {
        case let .success(reponse):
            if reponse.code == 200, let data = reponse.data {
                return .success(data, reponse.msg)
            } else {
                return .failure(message, APIError.responseError(APIResponseError.invalidParseResponse(CSDataError.invalidParseResponse)))
            }
        case let .failure(apiError):
            if apiError == APIError.networkError {
                message = apiError.localizedDescription
            }

            assertionFailure(apiError.localizedDescription)
            return .failure(message, apiError)
        }
    }
}

```



### 业务使用

```swift
enum HomeBannerAPI {
    struct HomeBannerRequest: CSAPIRequest {
        typealias DataResponse = HomeBanner

        var parameters: [String: Any]? {
            return nil
        }

        var path: String {
            return "/config/homeBanner"
        }
    }
}

APIService.sendRequest(HomeBannerAPI.HomeBannerRequest()) { reponse in
    switch reponse.result.validateResult {
    case let .success(info, _):
        /// 这个 Info 就是上面我们传入的 HomeBanner 类型
        print(info)
    case let .failure(_, error):
        print(error)
    }
}
```



## 未来规划

- 重试机制
- 缓存机制
