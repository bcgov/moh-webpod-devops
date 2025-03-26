resource "aws_efs_file_system" "hlbc_drupal_efs" {
  creation_token = "hlbc_drupal_efs"
  encrypted = true
}

resource "aws_efs_access_point" "sites" {
  file_system_id = aws_efs_file_system.hlbc_drupal_efs.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/sites"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0777"
    }
  }
}

resource "aws_efs_access_point" "modules" {
  file_system_id = aws_efs_file_system.hlbc_drupal_efs.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/modules"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0777"
    }
  }
}

resource "aws_efs_access_point" "profiles" {
  file_system_id = aws_efs_file_system.hlbc_drupal_efs.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/profiles"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0777"
    }
  }
}

resource "aws_efs_access_point" "themes" {
  file_system_id = aws_efs_file_system.hlbc_drupal_efs.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/themes"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0777"
    }
  }
}

resource "aws_efs_mount_target" "hlbc_drupal_efs_mount_target" {
  for_each        = toset(data.aws_subnets.app.ids)
  file_system_id  = aws_efs_file_system.hlbc_drupal_efs.id
  subnet_id       = each.value
  security_groups = [data.aws_security_group.app.id]
}