create table teacher
(
	Tno char(10) primary key,
	Tname char(20) not null,
	Tsex char(2) check(Tsex in('男','女')),
	Tage int check(Tage>0),
	Tsch char(20),
	Twage int check(Twage>4000)
)
create table student
(
Sno char(10) primary key,
Sname char(20) not null,
Ssex char(2) check (Ssex in('男','女')),
Sage int check(Sage>=2000),
Clno char(20) not null
)

create table class
(
	Clno char(20) primary key,
	Clname char(20) unique not null,
	Csch char(20),
	Cdept char(20),
	Ctchno char(10), 
	Cstuno char(10) ,
	foreign key(Ctchno) references teacher(Tno),
	foreign key(Cstuno) references student(Sno)
)
//在创建学生表时，班级编号参照班级表，而班级表的班长参照学生表。两者存在相互依赖的关系。因此，可以先创建表，创建完成后添加约束条件。
alter table student
add constraint c4 
foreign key(Clno) references class(Clno)

create table course
(
Cno char(10) primary key,
Cname char(20) not null,
Cpno char(10) references course(Cno),
Ccredit int check (Ccredit>0)
);

create table SC
(
Sno char(10),
Cno char(10),
Grade smallint check (Grade>=0 And Grade<=100),
Tno char(10),
primary key (Sno,Cno),
foreign key (Sno) references student(Sno)
on delete cascade 
on update cascade,
foreign key(Cno) references course(Cno)
on delete no action
on update cascade,
foreign key(Tno) references teacher(Tno)
)


create table TC
(
Tno char(10),
Cno char(10),
primary key(Tno,Cno),
foreign key(Tno) references teacher(Tno)
on delete cascade
on update cascade,
foreign key(Cno) references course(Cno)
on delete cascade
on update cascade
)
create index sno_index on student(Sno)
create index cno_index on course(Cno)
create index tno_index on teacher(Tno)
create index clno_index on class(clno)
create index sc_index on sc(sno,cno)
create index tc_index on sc(tno,cno)

//GP函数的计算
-- 更改语句分隔符为$$
DELIMITER $$

-- 创建绩点计算函数
CREATE FUNCTION GP(grade SMALLINT)
RETURNS DECIMAL(3,1)
DETERMINISTIC
READS SQL DATA
BEGIN
    -- 声明返回值变量
    DECLARE ret DECIMAL(3,1);
    
    -- 处理NULL值和非法输入
    IF grade IS NULL OR grade < 0 OR grade > 100 THEN
        SET ret = NULL;
    -- 根据成绩计算绩点
    ELSEIF grade < 60 THEN
        SET ret = 0;
    ELSE
        SET ret = (grade - 50) / 10.0;
    END IF;
    
    RETURN ret;
END$$

-- 恢复默认分隔符
DELIMITER ;

//总绩点GPA的函数

DELIMITER $$

CREATE FUNCTION GPA(Sno CHAR(10))
RETURNS DECIMAL(3,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE ret DECIMAL(3,2);
    DECLARE sumcredit DECIMAL(5,2);
    DECLARE gpcredit DECIMAL(5,2);
    
    -- 计算总学分
    SELECT SUM(Ccredit) INTO sumcredit
    FROM Course C
    JOIN SC ON C.Cno = SC.Cno
    WHERE SC.Sno = Sno;
    
    -- 计算加权绩点
    SELECT SUM(C.Ccredit * GP(SC.Grade)) INTO gpcredit
    FROM Course C
    JOIN SC ON C.Cno = SC.Cno
    WHERE SC.Sno = Sno;
    
    -- 处理没有选课或总学分为0的情况
    IF sumcredit IS NULL OR sumcredit = 0 THEN
        SET ret = 0;
    ELSE
        SET ret = gpcredit / sumcredit;
    END IF;
    
    RETURN ret;
END$$

DELIMITER ;

//视图
create view gradelist
as
select Student.Sno,Sname,Cname,grade
from Student,Sc,Course
where Student.Sno=Sc.Sno and Sc.Cno=Course.Cno
with check option	

CREATE VIEW CourseScore (Cno, Cname, ClassAvg)
AS
SELECT 
    C.Cno, 
    C.Cname, 
    AVG(SC.grade) AS ClassAvg
FROM 
    Course C
JOIN 
    SC ON C.Cno = SC.Cno
GROUP BY 
    C.Cno, C.Cname;

CREATE VIEW StudentGPA (Sno, GPA)
AS
SELECT 
    S.Sno, 
    GPA(S.Sno) AS GPA  
FROM 
    Student S;

create view studentschool
as
select student.Sno,class.Csch
from student,class
where student.Clno=class.Clno


//录入数据
//保持导师为空，后续插入
insert into class(Clno,Clname,Csch,Cdept,Cstuno)
values
('04092301','人工智能1','人工智能学院','人工智能',null),
('04092302','人工智能2','人工智能学院','人工智能',NULL)


insert into student(Sno,Sname,Ssex,Sage,Clno)
values
('2023211712','李昊','男',2003,'04092301'),
('2023211713','刘零','女',2003,'04092302'),
('2023211714','王刚','男',2002,'04092301'),
('2023211715','陈磊','男',2002,'04092302'),
('2023211716','杨敏','女',2003,'04092301')

update class
set cstuno = '2023211712'
where clno = '04092301';

update class
set cstuno = '2023211713'
where clno = '04092302';

SELECT * FROM Student WHERE Sno IN ('2023211713', '2023211716');
SELECT * FROM Class WHERE Clno IN ('04092301', '04092302');

insert into teacher(Tno,Tname,Tsex,Tage,Tsch,Twage)
values
('1000004331','王哥','男',1985,'计算机学院',8000),
('1000004332','黄娟','女',1976,'计算机学院',6000),
('1000004333','李磊','男',1990,'计算机学院',10000)

UPDATE teacher
set Tsch ='人工智能学院';
//更新班导师
update class
set Ctchno='1000004331'
where Clno='04092301';

update class
set Ctchno='1000004332'
where Clno='04092302';
//插入课程表
insert into course(Cno,Cname,Cpno,Ccredit)
values
('0000','计算机导论',null,1),
('0001','低等数学A1',null,5),
('0002','低等数学A2','0001',6),
('0003','计算机组成原理','0000',4)

//插入教师开课表
insert into TC(Cno,Tno)
values
('0000','1000004331'),
('0001','1000004332'),
('0001','1000004333'),
('0002','1000004332'),
('0003','1000004331')

//学生选课表
insert into SC(Sno,Cno,Grade,Tno)
values
('2023211712','0000',90,'1000004331'),
('2023211712','0001',80,'1000004333'),
('2023211713','0002',85,'1000004332'),
('2023211712','0003',95,'1000004331'),
('2023211713','0000',87,'1000004331')
SELECT* from sc;

//触发器1
DELIMITER $$

CREATE TRIGGER insert_or_update_sal
BEFORE INSERT ON teacher
FOR EACH ROW
BEGIN
    DECLARE wage INT;
    DECLARE tsch VARCHAR(20);
    SET wage = NEW.Twage;
    SET tsch = NEW.Tsch;
    IF wage < 5000 AND tsch = '人工智能学院' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = '工资过低!';
    END IF;
END$$

DELIMITER ;
//测试
INSERT INTO teacher (Tno, Tname, Tsex, Tage, Tsch, Twage)
VALUES ('1000004334', '张三', '男', 30, '人工智能学院', 4500);

//建立触发器，一门课的选课人数不能大于200

DELIMITER $$

CREATE TRIGGER sc_count
BEFORE INSERT ON SC
FOR EACH ROW
BEGIN
    DECLARE course_count INT;
    SELECT COUNT(*) INTO course_count
    FROM SC
    WHERE Cno = NEW.Cno;
    IF course_count >= 200 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = '选课人数已满！';
    END IF;
END$$

DELIMITER ;
//建立触发器，删除学生时删除他在选课表中的所有信息
DELIMITER $$

CREATE TRIGGER delete_SC
AFTER DELETE ON student
FOR EACH ROW
BEGIN
    DELETE FROM SC 
    WHERE Sno = OLD.Sno;
END$$

DELIMITER ;
//4门不及格
DELIMITER $$

CREATE TRIGGER grade_SC
AFTER UPDATE ON SC
FOR EACH ROW
BEGIN
    DECLARE fail_count INT;
    SELECT COUNT(*) INTO fail_count
    FROM SC
    WHERE Sno = NEW.Sno AND Grade < 60;
    IF fail_count >= 4 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = '不及格科目过多！';
    END IF;
END$$

DELIMITER ;


//权限设置
CREATE ROLE IF NOT EXISTS 'headmaster';
CREATE ROLE IF NOT EXISTS 'dean';
CREATE ROLE IF NOT EXISTS 'teacher';
CREATE ROLE IF NOT EXISTS 'student';

-- 授予校长角色全部权限
GRANT ALL PRIVILEGES ON sms.* TO 'headmaster' WITH GRANT OPTION;
GRANT CREATE USER ON *.* TO 'headmaster'; -- 允许创建用户

-- 授予教务处长角色全部权限
GRANT ALL PRIVILEGES ON sms.* TO 'dean' WITH GRANT OPTION;

-- 授予教师角色权限
GRANT SELECT ON sms.class TO 'teacher';
GRANT SELECT, INSERT, UPDATE, DELETE ON sms.course TO 'teacher';
GRANT SELECT, UPDATE(Grade) ON sms.SC TO 'teacher';
GRANT SELECT, INSERT, UPDATE, DELETE ON sms.TC TO 'teacher';
GRANT SELECT ON sms.teacher TO 'teacher';
GRANT SELECT ON sms.student TO 'teacher';

-- 授予学生角色权限
GRANT SELECT(Sno, Sname, Ssex, Sage, Clno) ON sms.student TO 'student';
GRANT UPDATE(Sname, Ssex, Sage) ON sms.student TO 'student';
GRANT SELECT, INSERT, DELETE ON sms.SC TO 'student';
GRANT SELECT ON sms.course TO 'student';
GRANT SELECT ON sms.TC TO 'student';
GRANT SELECT ON sms.teacher TO 'student';

CREATE USER IF NOT EXISTS 'h001'@'localhost' IDENTIFIED BY 'StrongHeadmasterPass123!';
GRANT 'headmaster' TO 'h001'@'localhost';

CREATE USER IF NOT EXISTS 'd001'@'localhost' IDENTIFIED BY 'StrongDeanPass456!';
GRANT 'dean' TO 'd001'@'localhost';

CREATE USER IF NOT EXISTS 't001'@'localhost' IDENTIFIED BY 'StrongTeacherPass789!';
GRANT 'teacher' TO 't001'@'localhost';

CREATE USER IF NOT EXISTS 's001'@'localhost' IDENTIFIED BY 'StrongStudentPass012!';
GRANT 'student' TO 's001'@'localhost';

-- 设置默认角色
SET DEFAULT ROLE ALL TO 
    'h001'@'localhost',
    'd001'@'localhost',
    't001'@'localhost',
    's001'@'localhost';

-- 刷新权限
FLUSH PRIVILEGES;

//测试
SHOW GRANTS FOR 'headmaster';
SHOW GRANTS FOR 'dean';
SHOW GRANTS FOR 'teacher';
SHOW GRANTS FOR 'student';

//GPA

select *
from studentGpa

//最高&最低
select max(grade),min(grade)
from sc
group by Cno

//新开课
Insert into TC
Values('1000004331','0002')
//查询学生所选课
select Sname
from student
where not exists(
	select *
	from course
	where not exists
		(
		select *
		from SC
		where Sno=student.Sno
		and Cno=Course.Cno
		)
	);
