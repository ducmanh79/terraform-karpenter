Completed
- 1.1 Core
- 1.2 - Bottlerocket, Basic metric / logging

TBD:
- TLS 
- Fine-tune

Explaination:
- TLS: về phần TLS cho ingress controller, em có 2 hướng xử lý đó là sử dụng cert-manager hoặc dùng AWS ACM, tuy nhiên em không có sở hữu domain riêng nên chưa thể triển khai trong bài lab này. Đối với cert-manager sẽ cần cài đặt crd, issuer và certificates, issuer e chọn sẽ là acme-issuer. Đối với ACM, em sẽ lưu key trong SSM và include vào cụm dưới dạng secret qua External Secret Operator.

- Fine-tune:
    - mixed on-demand/spot: do có 2 loại capacity được sử dụng là spot và on-demand, có thể sử dụng nodeAffinity với thuộc tính preferredDuringSchedulingIgnoredDuringExecution để fallback về dạng còn lại nếu không thể đáp ứng được capacity yêu cầu. 

    - Zero down time deployment: như hôm trước trong buổi phỏng vấn em có biết được là với dạng triển khai app hiện tại là GRPC, đồng nghĩa với việc connection vẫn sẽ tồn tại ngay cả khi pod bị loại khỏi service => chuẩn bị cho update. Với trường hợp này ngoài sử dụng deployment strategy, pre pull image và pod disruption budget như đã trao đổi trong buổi phỏng vấn, em xin bổ sung thêm 1 vài bước.
        - sử dụng pod lifecycle hook để xử lý terminate các session trước khi pod bị kill hoàn toàn
        - sử dụng maxSurge/maxUnavailable để cân bằng giữa việc ổn định của app và tốc độ triển khai version mới, cụ thể với maxUnavailable=0 và maxSurge=1, ta sẽ luôn có số pods chạy tương ứng replicas chỉ định và maxSurge cho phép triển khai thêm 1 pod trước khi các instance cũ bị terminate, giảm thời gian cold start của app.

- K6: script chạy k6 có thể được triển khai dạng job trong cụm và target vào đầu API /date của app NodeJS.