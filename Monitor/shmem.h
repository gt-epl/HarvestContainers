#include <linux/mutex.h>
#include <linux/errno.h>
#include <linux/uaccess.h>
#include <linux/mm.h>
#include <linux/kernel_stat.h>

#define SHMEM_SIZE (4096 * 32)
#define DEVICE_NAME "qidlecpu"
#define  CLASS_NAME "poll"
static struct class *class;
static struct device *device;
static int major;
static struct idleStats *sh_mem = NULL;

static DEFINE_MUTEX(qidlecpu_mutex);

static int qidlecpu_release(struct inode *inodep, struct file *filep)
{
    return 0;
}

static int qidlecpu_open(struct inode *inodep, struct file *filep)
{
    int ret = 0;
    return ret;
}

static int qidlecpu_mmap(struct file *filp, struct vm_area_struct *vma)
{
    int ret = 0;
    struct page *page = NULL;
    unsigned long size = (unsigned long)(vma->vm_end - vma->vm_start);

    if (size > SHMEM_SIZE) {
        ret = -EINVAL;
        goto out;
    }

    page = virt_to_page((unsigned long)sh_mem + (vma->vm_pgoff << PAGE_SHIFT));
    ret = remap_pfn_range(vma, vma->vm_start, page_to_pfn(page), size,
            vma->vm_page_prot);
    if (ret != 0) {
        goto out;
    }

out:
    return ret;
}

static ssize_t qidlecpu_read(struct file *filep, char *buffer, size_t len,
        loff_t *offset)
{
    int ret = 0;
    return ret;
}

static ssize_t qidlecpu_write(struct file *filep, const char *buffer,
        size_t len, loff_t *offset)
{
    return 0;
}

static const struct file_operations qidlecpu_fops = {
    .open = qidlecpu_open,
    .read = qidlecpu_read,
    .write = qidlecpu_write,
    .release = qidlecpu_release,
    .mmap = qidlecpu_mmap,
    .owner = THIS_MODULE,
};
