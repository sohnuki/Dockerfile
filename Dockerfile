#centos7のイメージを取得
FROM centos:7

#Dockerfile作成者
MAINTAINER s5g

#タイムゾーンの設定
RUN /bin/cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

#Apache2.4のインストール
RUN yum -y install httpd; yum clean all; systemctl enable httpd.service

#公開ポート
EXPOSE 80

#tmpディレクトリに移動
WORKDIR /tmp/

#tomcatユーザ作成
RUN useradd -s /sbin/nologin tomcat

#JDKのインストール
#OracleJDKをwgetやcurlで素直にダウンロードすることができないのは有名な話、ライセンス同意チェックのCookieを添えてやる
RUN curl -OL --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jdk-8u102-linux-x64.rpm
RUN rpm -ihv jdk-8u102-linux-x64.rpm

#Tomcat8のインストール
RUN curl -O http://ftp.meisei-u.ac.jp/mirror/apache/dist/tomcat/tomcat-8/v8.0.37/bin/apache-tomcat-8.0.37.tar.gz
RUN tar -xzvf apache-tomcat-8.0.37.tar.gz
RUN mv apache-tomcat-8.0.37 /usr/local

#環境変数設定
ENV CATALINA_HOME /usr/local/apache-tomcat-8.0.37
ENV JAVA_HOME /usr/java/jdk1.8.0_102
ENV PATH $PATH:$JAVA_HOME/bin:$CATALINA_HOME/bin

#DocumentRootディレクトリの所有者を変更
RUN chown -R tomcat:tomcat $CATALINA_HOME

#tomcat-users.xmlのバックアップ
RUN cp -p $CATALINA_HOME/conf/tomcat-users.xml $CATALINA_HOME/conf/tomcat-users.xml_`date +%Y%m%d`

#tomcatの設定ファイルに必要な情報をsedコマンドで書き換える
RUN sed -i -e 's#</tomcat-users>#<role rolename="manager-gui"/><user username="admin" password="password" roles="manager-gui"/></tomcat-users>#g' $CATALINA_HOME/conf/tomcat-users.xml

#httpdのconfファイルのバックアップ
RUN cp -p /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_`date +%Y%m%d`

#Apache+Tomcat連携
RUN sed -i -e '/foo_module/i \LoadModule proxy_module modules/mod_proxy.so' /etc/httpd/conf/httpd.conf
RUN sed -i -e '/foo_module/i \LoadModule proxy_ajp_module modules/mod_proxy_ajp.so' /etc/httpd/conf/httpd.conf
RUN echo -e "ProxyPass /manager/ ajp://localhost:8009/manager/\nProxyPass /examples/ ajp://localhost:8009/examples/" > /etc/httpd/conf.d/httpd-proxy.conf

#8080ポート塞ぐとかは手動でやる！

#firewall停止
RUN systemctl disable firewalld
#RUN systemctl stop firewalled

#tomcat起動
#CMD $CATALINA_HOME/bin/startup.sh
CMD ["catalina.sh", "run"]
