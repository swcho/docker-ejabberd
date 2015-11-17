
SHELL 				:= /bin/bash
NAME 				:= $(shell basename `pwd`)
TAG 				:= file-server:5000/$(NAME)
TEMP_PATH 			:= /tmp/docker/$(NAME)
TEMP_TEMPLATE_PATH 	:= $(TEMP_PATH)/.template
TARGET				:= $(TEMP_PATH)/.built
ALL_FILES			:= $(shell find -not -path './.git/*' -type f )
BUILD_VERSION		= "$(NAME) `git describe --abbrev=4 --dirty --always --tags`"
TEMPLATE_FILES = \
	Dockerfile \
	home/jenkins/config.dev.xml \
	home/jenkins/config.prd.xml \
	home/jenkins/config.test.xml \
	home/jenkins/hudson.plugins.jira.JiraProjectProperty.xml
TEMPLATE_FILES =
COPY_FILES = $(filter-out $(TEMPLATE_FILES), $(ALL_FILES))
ALL_FILES_TARGET = $(addprefix $(TEMP_PATH)/, $(ALL_FILES))
TEMPLATE_FILES_TARGET = $(addprefix $(TEMP_TEMPLATE_PATH)/, $(TEMPLATE_FILES))
NO_CACHE =

JIRA_USER_ID ?= $(shell bash -c 'read -p "Jira user ID: " jiraid; echo $$jiraid')
JIRA_USER_PASS ?= $(shell bash -c 'read -p "Jira user PASS: " jirapass; echo $$jirapass')
DOCKER_HOST_IP ?= $(shell bash -c 'read -p "IP address: " ipaddr; echo $$ipaddr')
DEPLOYMENT_OPT ?= $(shell bash -c 'read -p "Deployment Option: " depopt; echo $$depopt')
TEMPLATE_ARGS=export BUILD_VERSION=$(BUILD_VERSION); export JIRA_USER_ID=$(JIRA_USER_ID); export JIRA_USER_PASS=$(JIRA_USER_PASS);
TEMPLATE_ARGS=

OPTIONS_PORT 	=
OPTIONS_PORT 	+= -p 5222:5222
OPTIONS_PORT 	+= -p 5269:5269
OPTIONS_PORT 	+= -p 5280:5280
OPTIONS_VOLUME 	=  -v ~/docker_data/$(NAME):/home/jenkins
OPTIONS_VOLUME 	=
OPTIONS_ENV 	= -e DEPLOYMENT_OPT=$(DEPLOYMENT_OPT) -e HOST_IP=$(DOCKER_HOST_IP)
OPTIONS_ENV 	=

all: build

$(TEMP_PATH)/%: %
	@echo "COPY: $<"
	@mkdir -p $(@D)
	@cp $< $@

$(TEMP_TEMPLATE_PATH)/%: %
	@echo "TEMPLATE: $<"
	@mkdir -p $(@D)
	@$(TEMPLATE_ARGS) cat $< | skapalon > $@
	@cp $@ $(TEMP_PATH)/$<

$(TARGET): $(ALL_FILES_TARGET) $(TEMPLATE_FILES_TARGET)
	sudo docker build $(NO_CACHE) -t $(TAG) $(TEMP_PATH)
	touch $(TARGET)

build: $(TARGET)

push: build
	sudo docker push $(TAG)

test: rm build
	-@sudo rm -rf ~/docker_data/$(NAME)
	sudo docker run -it --rm --name $(NAME) $(OPTIONS_PORT) $(OPTIONS_VOLUME) $(OPTIONS_ENV) file-server:5000/$(NAME) bash

run: build
	sudo docker run -it -d --name $(NAME) $(OPTIONS_PORT) $(OPTIONS_VOLUME) $(OPTIONS_ENV) file-server:5000/$(NAME)

exec:
	sudo docker exec -it $(NAME) sudo -u jenkins -i

rm:
	-@sudo docker stop $(NAME) > /dev/null 2>&1
	-@sudo docker rm $(NAME) > /dev/null 2>&1

clean:
	rm -rf $(TEMP_PATH)

make_no_cache:
	$(eval NO_CACHE = --no-cache)

full_build: clean make_no_cache $(TARGET) push
