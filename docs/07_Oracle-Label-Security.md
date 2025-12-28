Chào bạn, đây là nội dung file PDF **"Bài thực hành số 7: ORACLE LABEL SECURITY (2)"** đã được chuyển đổi sang định dạng Markdown. Mình đã định dạng lại các đoạn mã SQL và cấu trúc văn bản để bạn dễ dàng theo dõi và thực hành.

---

# Bài thực hành số 7: ORACLE LABEL SECURITY (2)

### ❖ Tóm tắt nội dung:
*   Các loại nhãn người dùng
*   Các quyền đặc biệt trên chính sách
*   Các điều kiện áp dụng chính sách
*   Áp dụng chính sách cho bảng

---

## I. Các loại nhãn người dùng

### A. Lý thuyết

Trong bài *Lab 6 - Oracle Label Security (1)*, ở phần *I.A.4*, chúng ta đã nhắc đến quy trình cơ bản để xây dựng một chính sách OLS. Theo đó:
*   **B4:** Gán chính sách trên cho các bảng hoặc schema mà bạn muốn bảo vệ.
*   **B5:** Gán các giới hạn quyền, các nhãn người dùng hoặc các quyền truy xuất đặc biệt cho những người dùng liên quan.

Thứ tự của 2 bước trên như vậy là hợp lý, vì trong OLS, khi một chính sách được chỉ định bảo vệ cho một bảng/schema, kể từ thời điểm đó bất kỳ người dùng nào cũng không thể truy xuất vào bảng/schema đó trừ khi được gán cho các *nhãn người dùng* (user label) thích hợp hoặc được cấp những quyền đặc biệt đối với chính sách đó.

Tuy nhiên, để hiểu được tác dụng của các tùy chọn áp dụng chính sách ở bước 4, ta cần phải hiểu về các ràng buộc đối với người dùng khi truy xuất các bảng và schema được bảo vệ. Do vậy, để việc tìm hiểu về OLS được dễ dàng hơn, trong bài lab này sẽ tạm hoán đổi thứ tự tìm hiểu và thực hiện của bước 4 và bước 5. Khi đã hiểu và biết cách hiện thực một chính sách OLS, các bạn hãy thực hiện các bước theo đúng thứ tự của nó để đảm bảo tính bảo mật và toàn vẹn cho dữ liệu.

#### 1. Nhãn người dùng (user label)
*   Tại mỗi thời điểm, mỗi người dùng đều có một nhãn gọi là **nhãn người dùng (user label)**. Nhãn này có tác dụng cho biết mức độ tin cậy của người dùng đối với những dữ liệu được chính sách đó bảo vệ.
*   Nhãn người dùng cũng gồm các thành phần giống như nhãn dữ liệu. Khi một người dùng truy xuất trên bảng được bảo vệ, nhãn người dùng sẽ được so sánh với nhãn dữ liệu của mỗi dòng trong bảng để quyết định những dòng nào người dùng đó có thể truy xuất được.
*   OLS cung cấp 2 cách thức để quản lý các **user label**: gán cụ thể từng thành phần của nhãn cho user hoặc gán nguyên nhãn cho user.

Dù sử dụng hình thức quản lý nào, mỗi người dùng cũng có một **tập xác thực quyền (set of authorizations)** để lưu giữ thông tin về quyền hạn truy xuất đối với những dữ liệu được chính sách đó bảo vệ. Tập xác thực quyền gồm có:
*   **Level cao nhất (User Max Level)** của người dùng trong các tác vụ read và write.
*   **Level thấp nhất (User Min Level)** của người dùng trong các tác vụ write. User Min Level phải thấp hơn hoặc bằng User Max Level.
*   **Tập các compartment** được truy xuất.
*   **Tập các group** được truy xuất.
    *(Đối với mỗi compartment và group có lưu kèm thông tin quyền truy xuất được phép là quyền “chỉ đọc” (read-only) hay quyền “đọc-viết” (read-write))*

**Session label:**
*   Session label là một user label mà người dùng sử dụng để truy xuất dữ liệu trong một session làm việc. Session label có thể là một tổ hợp bất kỳ các thành phần nằm trong giới hạn tập xác thực quyền của user đó.
*   Người quản trị có thể mô tả session label mặc định cho người dùng khi thiết lập tập xác thực quyền cho người dùng đó.
*   Bản thân người dùng có thể thay đổi session label của mình thành một nhãn bất kỳ với điều kiện là nhãn mới nằm trong giới hạn xác thực quyền của họ.

**Row label:**
*   Khi một hàng mới được insert vào một bảng đang được bảo vệ, cần có một nhãn dữ liệu (data label) được chỉ định cho hàng dữ liệu mới đó. Hoặc khi một hàng được update, nhãn dữ liệu của hàng đó cũng có thể bị thay đổi.
*   **Row label** là từ dùng để chỉ những nhãn được áp dụng cho các hàng dữ liệu khi hàng đó được update hoặc insert.
*   Khi insert/update, người dùng có thể mô tả tường minh row label cho dòng dữ liệu mới được insert/update, với điều kiện row label phải thỏa đồng thời các điều kiện sau:
    *   Level thấp hơn hoặc bằng max level của người dùng đó.
    *   Level cao hơn hoặc bằng min level của người dùng đó.
    *   Chỉ được chứa các compartment xuất hiện trong session label hiện tại của người dùng đó và người dùng có quyền *viết (write)* trên các compartment đó.
    *   Chỉ được chứa các group xuất hiện trong session label hiện tại của người dùng đó và người dùng có quyền *viết (write)* trên các group đó.

#### 2. Quản lý người dùng theo từng loại thành phần của nhãn
Để gán quyền theo cách này ta cần chỉ định ra cụ thể các *level, compartment, group* mà một user có thể truy xuất.

**Quản lý các level:** gồm có 4 thông số:
*   **max_level:** level cao nhất mà người dùng có quyền đọc và viết. Đây là “giới hạn trên” cho việc truy xuất.
*   **min_level:** level thấp nhất mà người dùng có quyền write. Đây là “giới hạn dưới” cho tác vụ viết. “Giới hạn dưới” cho tác vụ đọc chính là level thấp nhất mà chính sách đó quy định.
*   **def_level:** level cho session label mặc định của người dùng (phải thỏa `min level <= default level <= max level`). Nếu không mô tả, mặc định sẽ là `max level`.
*   **row_level:** level cho row label mặc định của người dùng, dùng để gán nhãn cho dữ liệu mà user đó tạo (phải thỏa `min level <= row level <= max level`). Nếu không mô tả, mặc định sẽ là `default level`.

**Quản lý các compartment:** Gồm 4 thông số chính (`read_comps`, `write_comps`, `def_comps`, `row_comps`).
**Quản lý các group:** Gồm 4 thông số chính (`read_groups`, `write_groups`, `def_groups`, `row_groups`).

> **Lưu ý:** nếu người dùng có quyền đọc trên một group thì đồng thời cũng có quyền đọc trên tất cả các group con (trực tiếp và gián tiếp) của group đó. Tương tự đối với quyền viết cũng vậy.

#### 3. Quản lý người dùng thông qua các nhãn
Để tiện lợi hơn, OLS cho phép thiết lập tập xác thực quyền thông qua việc gán các nhãn thay vì chỉ định từng thành phần riêng. Các loại nhãn cần mô tả:
*   **max_read_label:** nhãn thể hiện mức truy xuất cao nhất đối với tác vụ đọc.
*   **max_write_label:** nhãn thể hiện mức truy xuất cao nhất đối với quyền viết.
*   **min_write_label:** nhãn thể hiện mức truy xuất thấp nhất đối với tác vụ viết.
*   **def_read_label:** là session label mặc định cho các tác vụ đọc.
*   **def_write_label:** là session label mặc định cho tác vụ write.
*   **row_label:** nhãn mặc định dùng để gán nhãn cho các dòng dữ liệu mà user tạo ra.

> **Lưu ý:** do `def_write_label` là nhãn được tính tự động từ `def_read_label`, người quản trị không cần phải thao tác trên nó nên trong các tài liệu hướng dẫn của Oracle `def_read_label` thường được gọi là `def_label`.

#### 4. Giải thuật bảo mật của OLS đối với tác vụ đọc
Người dùng chỉ có thể đọc được dữ liệu khi thỏa đồng thời các điều kiện sau:
*   Level của session label cao hơn hoặc bằng level của dữ liệu.
*   Session label có chứa ít nhất một group nằm trong các group của data label hoặc có chứa group cha của ít nhất một group nằm trong data label.
*   Session label có chứa tất cả các compartment xuất hiện trong data label.

#### 5. Giải thuật bảo mật của OLS đối với tác vụ viết
Người dùng chỉ có thể viết được dữ liệu khi đồng thời thỏa 2 điều kiện sau:
*   **Điều kiện về level:** Level của data label phải thấp hơn hoặc bằng level của session label hiện tại và cao hơn hoặc bằng `min_level` của người dùng.
*   **Điều kiện về group và compartment:**
    *   Nếu data label không có group: session label phải có quyền viết đối với tất cả các compartment mà data label đó có.
    *   Nếu data label có chứa group: session label phải có quyền viết trên ít nhất một group trong data label (hoặc group cha). Bên cạnh đó, session label cũng phải chứa tất cả các compartment xuất hiện trong data label.

#### 6. Các quyền đặc biệt trong OLS
Các quyền đặc biệt được OLS định nghĩa gồm có 2 nhóm:

**Quyền truy xuất đặc biệt (Special Access Privilege):**
*   **READ:** quyền xem (SELECT) tất cả các dữ liệu do chính sách bảo vệ.
*   **FULL:** quyền viết và xem tất cả các dữ liệu do chính sách bảo vệ.
*   **COMPACCESS:** truy xuất dữ liệu dựa trên compartment, bỏ qua việc xác thực group.
*   **PROFILE_ACCESS:** cho phép thay đổi các session label của bản thân và session privilege của người dùng khác.

**Quyền đặc biệt trên row label (Special Row Label Privilege):**
*   **WRITEUP:** cho phép nâng level của một hàng dữ liệu (tối đa đến `max_level`).
*   **WRITEDOWN:** cho phép hạ level của một hàng dữ liệu (tối đa xuống đến `min_level`).
*   **WRITEACROSS:** cho phép thay đổi compartment và group của một hàng dữ liệu nhưng không thay đổi level.

---

### B. Thực hành

#### 1. Gán quyền người dùng theo các thành phần của nhãn
Louise Doran là nhân viên thuộc phòng Sales.

*   **Gán level:**
    ```sql
    CONN hr_sec/hrsec;
    BEGIN
        sa_user_admin.set_levels (
            policy_name => 'ACCESS_LOCATIONS',
            user_name   => 'LDORAN',
            max_level   => 'CONF',
            min_level   => 'PUB',
            def_level   => 'CONF',
            row_level   => 'CONF');
    END;
    /
    ```

*   **Gán compartment:**
    ```sql
    CONN hr_sec/hrsec;
    BEGIN
        sa_user_admin.set_compartments (
            policy_name => 'ACCESS_LOCATIONS',
            user_name   => 'LDORAN',
            read_comps  => 'SM,HR',
            write_comps => 'SM',
            def_comps   => 'SM',
            row_comps   => 'SM');
    END;
    /
    ```

*   **Gán group:**
    ```sql
    CONN hr_sec/hrsec;
    BEGIN
        sa_user_admin.set_groups (
            policy_name  => 'ACCESS_LOCATIONS',
            user_name    => 'LDORAN',
            read_groups  => 'UK,CA',
            write_groups => 'UK',
            def_groups   => 'UK',
            row_groups   => 'UK');
    END;
    /
    ```

#### 2. Gán quyền người dùng theo các nhãn
Karen Partner là trưởng phòng Sales.

```sql
CONN hr_sec/hrsec;
BEGIN
    sa_user_admin.set_user_labels (
        policy_name      => 'ACCESS_LOCATIONS',
        user_name        => 'KPARTNER',
        max_read_label   => 'SENS:SM,HR:UK,CA',
        max_write_label  => 'SENS:SM:UK',
        min_write_label  => 'CONF',
        def_label        => 'SENS:SM,HR:UK',
        row_label        => 'SENS:SM:UK');
END;
/
```

#### 3. Gán các quyền đặc biệt
*   Steven King là tổng giám đốc, cấp quyền **FULL**:
    ```sql
    CONN hr_sec/hrsec;
    BEGIN
        sa_user_admin.set_user_privs (
            policy_name => 'ACCESS_LOCATIONS',
            user_name   => 'SKING',
            PRIVILEGES  => 'FULL');
    END;
    /
    ```

*   Neena Kochhar là giám đốc điều hành, cấp quyền **READ**:
    ```sql
    CONN hr_sec/hrsec;
    BEGIN
        sa_user_admin.set_user_privs (
            policy_name => 'ACCESS_LOCATIONS',
            user_name   => 'NKOCHHAR',
            PRIVILEGES  => 'READ');
    END;
    /
    ```

---

## II. Áp dụng chính sách OLS

### A. Lý thuyết

#### 1. Đối tượng được bảo vệ
OLS cho phép gán chính sách theo 2 cấp độ: **cấp schema** và **cấp bảng**.
*   Nếu gán cho schema: tất cả các bảng thuộc schema đều được bảo vệ.
*   Nếu gán cho bảng: chỉ bảng đó được bảo vệ.
*   *Lưu ý:* Tùy chọn ở cấp độ bảng sẽ override tùy chọn ở cấp độ schema.

#### 2. Các thao tác quản trị
*   **Apply:** Gán chính sách.
*   **Remove:** Loại bỏ chính sách (cột chứa nhãn vẫn còn trong table).
*   **Enable/Disable:** Bật/Tắt chính sách tạm thời.

#### 3. Các tùy chọn cho việc áp dụng chính sách
*   **LABEL_DEFAULT:** Sử dụng row label mặc định của user làm nhãn cho hàng mới insert.
*   **LABEL_UPDATE:** Bật tùy chọn này thì user muốn đổi nhãn dữ liệu phải có quyền WRITEUP, WRITEDOWN hoặc WRITEACROSS.
*   **CHECK_CONTROL:** Kiểm tra xem nhãn mới sau khi update/insert có vượt quá quyền của user không.
*   **READ_CONTROL:** Áp dụng giải thuật bảo mật cho tác vụ đọc (SELECT, UPDATE, DELETE).
*   **WRITE_CONTROL:** Áp dụng giải thuật bảo mật cho tác vụ viết (INSERT, UPDATE, DELETE).
*   **ALL_CONTROL:** Áp dụng mọi ràng buộc.
*   **NO_CONTROL:** Không áp dụng bất cứ ràng buộc nào (thường dùng khi mới gán chính sách để chuẩn bị dữ liệu).

#### 4. Gán nhãn cho dữ liệu
Có 3 cách:
1.  Gán tường minh qua lệnh INSERT/UPDATE.
2.  Thiết lập tùy chọn LABEL_DEFAULT.
3.  Viết labeling function.

---

### B. Thực hành

#### 1. Áp dụng chính sách cho bảng
Gán chính sách `ACCESS_LOCATIONS` cho bảng `LOCATIONS` của schema `HR` với tùy chọn `NO_CONTROL`.

```sql
CONN sec_admin/secadmin;
BEGIN
    sa_policy_admin.apply_table_policy (
        policy_name   => 'ACCESS_LOCATIONS',
        schema_name   => 'HR',
        table_name    => 'LOCATIONS',
        table_options => 'NO_CONTROL');
END;
/
```

Kiểm tra bảng sau khi gán (cột `OLS_COLUMN` được thêm vào):
```sql
CONN hr/hr;
DESCRIBE locations;
```

#### 2. Gán nhãn cho dữ liệu
Cần gán quyền cho `sec_admin` để thao tác dữ liệu:
```sql
CONN hr/hr;
GRANT select, insert, update ON locations TO sec_admin;
```

Gán nhãn cho các dòng dữ liệu (sử dụng hàm `char_to_label` để chuyển chuỗi nhãn thành tag number):

*   Gán nhãn **CONF** cho toàn bộ bảng:
    ```sql
    CONN sec_admin/secadmin;
    UPDATE hr.locations SET ols_column = char_to_label('ACCESS_LOCATIONS', 'CONF');
    ```

*   Cập nhật nhãn cho các nước Mỹ, Anh, Canada:
    ```sql
    UPDATE hr.locations SET ols_column = char_to_label('ACCESS_LOCATIONS', 'CONF::US')
    WHERE country_id = 'US';

    UPDATE hr.locations SET ols_column = char_to_label('ACCESS_LOCATIONS', 'CONF::UK')
    WHERE country_id = 'UK';

    UPDATE hr.locations SET ols_column = char_to_label('ACCESS_LOCATIONS', 'CONF::CA')
    WHERE country_id = 'CA';
    ```

*   Gán nhãn đặc biệt cho một số địa chỉ cụ thể:
    ```sql
    UPDATE hr.locations SET ols_column = char_to_label('ACCESS_LOCATIONS', 'CONF:SM:UK,CA')
    WHERE (country_id = 'CA' and city = 'Toronto')
       OR (country_id = 'UK' and city = 'Oxford');

    UPDATE hr.locations SET ols_column = char_to_label('ACCESS_LOCATIONS', 'CONF:HR:UK')
    WHERE country_id = 'UK' and city = 'London';

    UPDATE hr.locations SET ols_column = char_to_label('ACCESS_LOCATIONS', 'SENS:HR,SM,FIN:CORP')
    WHERE country_id = 'CH' and city = 'Geneva';

    COMMIT;
    ```

Sau khi gán nhãn xong, ta cần kích hoạt bảo vệ bằng cách remove chính sách cũ (NO_CONTROL) và apply lại với các tùy chọn kiểm soát đầy đủ:

```sql
CONN sec_admin/secadmin;
BEGIN
    sa_policy_admin.remove_table_policy (
        policy_name => 'ACCESS_LOCATIONS',
        schema_name => 'HR',
        table_name  => 'LOCATIONS');

    sa_policy_admin.apply_table_policy (
        policy_name   => 'ACCESS_LOCATIONS',
        schema_name   => 'HR',
        table_name    => 'LOCATIONS',
        table_options => 'READ_CONTROL,WRITE_CONTROL,CHECK_CONTROL');
END;
/
```

---

## III. Bài tập

1.  Tạo bảng **CUSTOMERS** để áp dụng chính sách `region_policy` (đã tạo trong phần bài tập của Lab 06). Sau đó insert dữ liệu vào.

    ```sql
    CREATE TABLE customers (
        id          NUMBER(10) NOT NULL,
        cust_type   VARCHAR2(10),
        first_name  VARCHAR2(30),
        last_name   VARCHAR2(30),
        region      VARCHAR2(5),
        credit      NUMBER(10,2),
        CONSTRAINT customer_pk PRIMARY KEY (id)
    );
    ```

    **Vùng giá trị của một số cột:**
    *   `cust_type`: silver, gold, platinum
    *   `region`: north, west, east, south
    *   `credit`: SV cần nhập dữ liệu đủ cho 3 trường hợp tương ứng với 3 khoảng giá trị: >2000, từ 500 đến 2000, < 500.

    **Yêu cầu:**
    *   Tạo ra các user: `sales_manager`, `sales_north`, `sales_west`, `sales_east`, `sales_south`.
    *   Cấp quyền để các user này kết nối vào CSDL.
    *   Gán user label cho các user vừa tạo (SV tự xác định user label cho từng user sao cho hợp lý).